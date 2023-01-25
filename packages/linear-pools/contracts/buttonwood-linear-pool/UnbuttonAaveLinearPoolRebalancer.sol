// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUnbuttonToken.sol";
import "./interfaces/IAToken.sol";
import "./interfaces/ILendingPool.sol";
import "./UnbuttonExchangeRateModel.sol";

import "@balancer-labs/v2-interfaces/contracts/pool-utils/ILastCreatedPoolFactory.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";

import "@balancer-labs/v2-pool-linear/contracts/LinearPoolRebalancer.sol";

contract UnbuttonAaveLinearPoolRebalancer is LinearPoolRebalancer {
    using SafeERC20 for IERC20;
    using FixedPoint for uint256;
    // Underlying asset for _mainToken
    // Example AMPL token
    IERC20 private _baseToken;
    // Underlying asset for _wrappedToken
    // Aave interest bearing token
    IERC20 private _aaveToken;
    ILendingPool private _aaveLendingPool;
    UnbuttonExchangeRateModel private immutable _exchangeRateModel;

    // These Rebalancers can only be deployed from a factory to work around a circular dependency: the Pool must know
    // the address of the Rebalancer in order to register it, and the Rebalancer must know the address of the Pool
    // during construction.
    constructor(
        IVault vault,
        IBalancerQueries queries
    ) LinearPoolRebalancer(ILinearPool(ILastCreatedPoolFactory(msg.sender).getLastCreatedPool()), vault, queries) {
        ILinearPool pool = ILinearPool(ILastCreatedPoolFactory(msg.sender).getLastCreatedPool());
        _exchangeRateModel = new UnbuttonExchangeRateModel(
            IUnbuttonToken(address(pool.getMainToken())),
            IUnbuttonToken(address(pool.getWrappedToken()))
        );
    }

    modifier onlyOnce() {
        if (address(_baseToken) == address(0) || address(_aaveToken) == address(0)) {
            _;
        }
    }

    // TODO: Make sure this function accepts the main amount not the wrapped amount
    function _wrapTokens(uint256 amount) internal override {
        // Initialize global variables if not already done\
        initializeBridgeAssets();
        // convert wAMPL to AMPL
        uint256 baseTokenAmount = IUnbuttonToken(address(_mainToken)).burn(amount);
        // convert AMPL to Aave interest bearing AMPL (aAMPL)

        // approve wrapper before depositing
        _baseToken.safeApprove(address(_aaveLendingPool), baseTokenAmount);
        _aaveLendingPool.deposit(address(_baseToken), baseTokenAmount, address(this), 0);

        uint256 aaveTokenBalance = _aaveToken.balanceOf(address(this));
        // deposit aave interest bearing token (aAMPL) to wrap into the desired _wrappedToken (ubAAMPL)
        // approve wrapper before depositing
        _aaveToken.safeApprove(address(_wrappedToken), aaveTokenBalance);
        IUnbuttonToken(address(_wrappedToken)).deposit(aaveTokenBalance);
    }

    function _unwrapTokens(uint256 amountWrapped) internal override {
        // Initialize global variables if not already done
        initializeBridgeAssets();

        // convert ubAAMPLto aaveAMPL
        uint256 aaveTokenAmount = IUnbuttonToken(address(_wrappedToken)).burn(amountWrapped) - 1;

        // withdraw AMPL from the aave liquidity pool
        uint256 baseTokenAmount = _aaveLendingPool.withdraw(address(_baseToken), aaveTokenAmount, address(this));

        // wrap AMPL into wAMPL
        // Approve the token transfer before depositing
        _baseToken.safeApprove(address(_mainToken), baseTokenAmount);
        IUnbuttonToken(address(_mainToken)).deposit(baseTokenAmount);
    }

    function _getRequiredTokensToWrap(uint256 wrappedAmount) internal view override returns (uint256) {
        uint256 rate = _exchangeRateModel.calculateExchangeRate();
        return wrappedAmount.mulUp(rate) + 1;
    }

    // This function will run only once in the lifetime of the contract if the global variables are not yet initialized
    // We set these in order to be able to wrap and unwrap tokens due to the underlying tokens not being the same
    function initializeBridgeAssets() internal onlyOnce {
        _baseToken = IERC20(IUnbuttonToken(address(_mainToken)).underlying());
        _aaveToken = IERC20(IUnbuttonToken(address(_wrappedToken)).underlying());
        _aaveLendingPool = IAToken(address(_aaveToken)).POOL();
    }
}

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

import "@balancer-labs/v2-interfaces/contracts/pool-utils/ILastCreatedPoolFactory.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";

import "@balancer-labs/v2-pool-linear/contracts/LinearPoolRebalancer.sol";

contract UnbuttonAaveLinearPoolRebalancer is LinearPoolRebalancer {
    using SafeERC20 for IERC20;

    // These Rebalancers can only be deployed from a factory to work around a circular dependency: the Pool must know
    // the address of the Rebalancer in order to register it, and the Rebalancer must know the address of the Pool
    // during construction.
    constructor(
        IVault vault,
        IBalancerQueries queries
    ) LinearPoolRebalancer(ILinearPool(ILastCreatedPoolFactory(msg.sender).getLastCreatedPool()), vault, queries) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _wrapTokens(uint256 amount) internal override {
        // No referral code, depositing from underlying (i.e. DAI, USDC, etc. instead of aDAI or aUSDC). Before we can
        // deposit however, we need to approve the wrapper in the underlying token.
        _mainToken.safeApprove(address(_wrappedToken), amount);
        IUnbuttonToken(address(_wrappedToken)).deposit(amount);
    }

    function _unwrapTokens(uint256 amount) internal override {
        // Withdrawing into underlying (i.e. DAI, USDC, etc. instead of aDAI or aUSDC). Approvals are not necessary here
        // as the wrapped token is simply burnt.
        IUnbuttonToken(address(_wrappedToken)).withdraw(amount);
    }

    function _getRequiredTokensToWrap(uint256 wrappedAmount) internal view override returns (uint256) {
        // 1e18 wAaveAMPL = r1 aaveAMPL
        uint256 r1 = IUnbuttonToken(address(_wrappedToken)).wrapperToUnderlying(wrappedAmount);

        // r1 aaveAMPL = r1 AMPL (AMPL and aaveAMPL have a 1:1 exchange rate)

        // r1 AMPL = r2 wAMPL
        return IUnbuttonToken(address(_mainToken)).underlyingToWrapper(r1) + 1;
    }
}

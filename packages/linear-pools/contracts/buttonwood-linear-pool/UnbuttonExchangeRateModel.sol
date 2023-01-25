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

import "./interfaces/IUnbuttonToken.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-pool-utils/contracts/lib/ExternalCallLib.sol";

import "hardhat/console.sol";

contract UnbuttonExchangeRateModel {
    using FixedPoint for uint256;

    IUnbuttonToken private immutable _mainToken;
    IUnbuttonToken private immutable _wrappedToken;

    constructor(IUnbuttonToken mainToken, IUnbuttonToken wrappedToken) {
        _mainToken = mainToken;
        _wrappedToken = wrappedToken;
    }

    function calculateExchangeRate() external view returns (uint256) {
        // Calculate the rate for wrappedTokens to Aave Interest aTokens
        uint256 aaveBalance = _wrappedToken.totalUnderlying();
        uint256 wrappedSupply = _wrappedToken.totalSupply();
        // aToken rate == base token rate (AMPL)
        uint256 wrappedToAave = FixedPoint.ONE.mulUp(aaveBalance).divUp(wrappedSupply);
        console.log("wrapped to aave: ", wrappedToAave);
        // Calculate the rate for wrappedTokens to Aave Interest aTokens
        uint256 baseBalance = _mainToken.totalUnderlying();
        uint256 mainSupply = _mainToken.totalSupply();

        uint256 mainToAave = FixedPoint.ONE.mulUp(mainSupply).divUp(baseBalance);
        console.log("Exchange Rate: ", wrappedToAave.mulUp(mainToAave));
        return wrappedToAave.mulUp(mainToAave);
    }
}

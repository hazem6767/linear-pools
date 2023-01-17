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

// https://github.com/buttonwood-protocol/button-wrappers/blob/main/contracts/UnbuttonToken.sol

pragma solidity ^0.7.0;

import "../interfaces/IButtonWrapper.sol";

import "@orbcollective/shared-dependencies/contracts/MockMaliciousQueryReverter.sol";
import "@orbcollective/shared-dependencies/contracts/TestToken.sol";

contract MockUnbuttonERC20 is TestToken, IButtonWrapper, MockMaliciousQueryReverter {
    address private immutable _underlying;
    uint256 private _underlyingToWrapperRate;
    uint256 private _wrapperToUnderlyingRate;

    constructor(
        address underlying,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) TestToken(name, symbol, decimals) {
        _underlying = underlying;
    }

    function deposit(uint256 /*uAmount*/) external pure override returns (uint256) {
        return 0;
    }

    function withdraw(uint256 /*uAmount*/) external pure override returns (uint256) {
        return 0;
    }

    function underlying() external view override returns (address) {
        return _underlying;
    }

    function underlyingToWrapper(uint256 uAmount) external view override returns (uint256) {
        maybeRevertMaliciously();
        return uAmount;
    }

    function wrapperToUnderlying(uint256 amount) external view override returns (uint256) {
        maybeRevertMaliciously();
        return amount;
    }
}

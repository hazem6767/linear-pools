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
pragma solidity >=0.7.0 <0.9.0;
import "@orbcollective/shared-dependencies/contracts/TestToken.sol";
import "../interfaces/IAToken.sol";

contract MockAToken is TestToken, IAToken {
    address private _underlying;

    constructor(
        address underlying,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) TestToken(name, symbol, decimals) {
        _underlying = underlying;
    }

    function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
        return _underlying;
    }
}

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

import "@balancer-labs/v2-pool-utils/contracts/Version.sol";
import "@balancer-labs/v2-pool-linear/contracts/LinearPool.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

import "./interfaces/ITetuSmartVault.sol";

import "./TetuShareValueHelper.sol";

contract TetuLinearPool is LinearPool, Version, TetuShareValueHelper {
    IERC20 private immutable _mainToken;
    IERC20 private immutable _wrappedToken;

    uint256 private immutable _rateScaleFactor;

    struct ConstructorArgs {
        IVault vault;
        string name;
        string symbol;
        IERC20 mainToken;
        IERC20 wrappedToken;
        address assetManager;
        uint256 upperTarget;
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        address owner;
        string version;
    }

    constructor(ConstructorArgs memory args)
        LinearPool(
            args.vault,
            args.name,
            args.symbol,
            args.mainToken,
            args.wrappedToken,
            args.upperTarget,
            _toAssetManagerArray(args),
            args.swapFeePercentage,
            args.pauseWindowDuration,
            args.bufferPeriodDuration,
            args.owner
        )
        Version(args.version)
    {
        ITetuSmartVault tokenVault = ITetuSmartVault(address(args.wrappedToken));

        _require(address(args.mainToken) == tokenVault.underlying(), Errors.TOKENS_MISMATCH);

        _mainToken = args.mainToken;
        _wrappedToken = args.wrappedToken;

        _rateScaleFactor = 10**(SafeMath.sub(18, ERC20(tokenVault.underlying()).decimals()));
    }

    function _toAssetManagerArray(ConstructorArgs memory args) private pure returns (address[] memory) {
        // We assign the same asset manager to both the main and wrapped tokens.
        address[] memory assetManagers = new address[](2);
        assetManagers[0] = args.assetManager;
        assetManagers[1] = args.assetManager;

        return assetManagers;
    }

    function _getWrappedTokenRate() internal view override returns (uint256) {
        return Math.add(_getTokenRate(address(_wrappedToken)), 1);
    }
}

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

import "@balancer-labs/v2-pool-utils/contracts/lib/ExternalCallLib.sol";
import "@balancer-labs/v2-pool-utils/contracts/Version.sol";

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ERC20.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

import "@balancer-labs/v2-pool-linear/contracts/LinearPool.sol";

/**
 *      Unbutton wrapper: https://github.com/buttonwood-protocol/button-wrappers/blob/main/contracts/UnbuttonToken.sol
 */
contract UnbuttonAaveLinearPool is LinearPool, Version {
    struct ConstructorArgs {
        IVault vault;
        string name;
        string symbol;
        IUnbuttonToken mainToken;
        IUnbuttonToken wrappedToken;
        address assetManager;
        uint256 upperTarget;
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        address owner;
        string version;
    }

    constructor(
        ConstructorArgs memory args
    )
        LinearPool(
            args.vault,
            args.name,
            args.symbol,
            args.mainToken,
            args.wrappedToken,
            args.upperTarget,
            new address[](2),
            args.swapFeePercentage,
            args.pauseWindowDuration,
            args.bufferPeriodDuration,
            args.owner
        )
        Version(args.version)
    {
        // ex. wAMPL.underlying() == AMPL
        address mainUnderlying = args.mainToken.underlying();

        // ex. wAaveAMPL.underlying() == aaveAMPL
        // aaveAMPL.UNDERLYING_ASSET_ADDRESS() == AMPL
        address wrappedUnderlying = IAToken(args.wrappedToken.underlying()).UNDERLYING_ASSET_ADDRESS();

        _require(mainUnderlying == wrappedUnderlying, Errors.TOKENS_MISMATCH);
    }

    /*
     * @dev This function returns the exchange rate between the main token and
     *      the wrapped token as a 18 decimal fixed point number.
     *      In our case, it's the exchange rate between wAMPL and wAaveAMPL
     *      (i.e., the number of wAMPL for each wAaveAMPL).
     *      All UnbuttonTokens have 18 decimals, so it is not necessary to
     *      query decimals for the main token or wrapped token.
     */
    function _getWrappedTokenRate() internal view override returns (uint256) {
        // 1e18 wAaveAMPL = r1 aaveAMPL
        uint256 r1 = IUnbuttonToken(address(getWrappedToken())).wrapperToUnderlying(FixedPoint.ONE);

        // r1 aaveAMPL = r1 AMPL (AMPL and aaveAMPL have a 1:1 exchange rate)

        // r1 AMPL = r2 wAMPL
        uint256 r2 = IUnbuttonToken(address(getMainToken())).underlyingToWrapper(r1);

        // 1e18 wAaveAMPL = r2 wAMPL
        return r2;
    }
}

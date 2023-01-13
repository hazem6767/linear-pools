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

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBalancerQueries.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/ILastCreatedPoolFactory.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-utils/IFactoryCreatedPoolVersion.sol";

import "@balancer-labs/v2-pool-utils/contracts/Version.sol";
import "@balancer-labs/v2-pool-utils/contracts/factories/BasePoolFactory.sol";
import "@balancer-labs/v2-pool-utils/contracts/factories/FactoryWidePauseWindow.sol";

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Create2.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ReentrancyGuard.sol";

import "./UnbuttonAaveLinearPool.sol";

contract UnbuttonAaveLinearPoolFactory is
    ILastCreatedPoolFactory,
    IFactoryCreatedPoolVersion,
    BasePoolFactory,
    Version,
    ReentrancyGuard
{
    // Associate a name with each registered protocol that uses this factory.
    struct ProtocolIdData {
        string name;
        bool registered;
    }

    IBalancerQueries private immutable _queries;

    address private _lastCreatedPool;
    string private _poolVersion;

    // Maintain a set of recognized protocolIds.
    mapping(uint256 => ProtocolIdData) private _protocolIds;

    // This event allows off-chain tools to differentiate between different protocols that use this factory
    // to deploy UnbuttonAave Linear Pools.
    event UnbuttonAaveLinearPoolCreated(address indexed pool, uint256 indexed protocolId);

    // Record protocol ID registrations.
    event UnbuttonAaveLinearPoolProtocolIdRegistered(uint256 indexed protocolId, string name);

    constructor(
        IVault vault,
        IProtocolFeePercentagesProvider protocolFeeProvider,
        IBalancerQueries queries,
        string memory factoryVersion,
        string memory poolVersion,
        uint256 initialPauseWindowDuration,
        uint256 bufferPeriodDuration
    )
        BasePoolFactory(
            vault,
            protocolFeeProvider,
            initialPauseWindowDuration,
            bufferPeriodDuration,
            type(UnbuttonAaveLinearPool).creationCode
        )
        Version(factoryVersion)
    {
        _queries = queries;
        _poolVersion = poolVersion;
    }

    /**
     * @dev Return the address of the most recently created pool.
     */
    function getLastCreatedPool() external view override returns (address) {
        return _lastCreatedPool;
    }

    /**
     * @dev Return the pool version deployed by this factory.
     */
    function getPoolVersion() public view override returns (string memory) {
        return _poolVersion;
    }

    /**
     * @dev Return the name associated with the given protocolId, if registered.
     */
    function getProtocolName(uint256 protocolId) external view returns (string memory) {
        ProtocolIdData memory protocolIdData = _protocolIds[protocolId];

        require(protocolIdData.registered, "Protocol ID not registered");

        return protocolIdData.name;
    }

    /**
     * @dev Deploys a new `UnbuttonAaveLinearPool`.
     */
    function create(
        string memory name,
        string memory symbol,
        IUnbuttonToken mainToken,
        IUnbuttonToken wrappedToken,
        uint256 upperTarget,
        uint256 swapFeePercentage,
        address owner,
        uint256 protocolId
    ) external nonReentrant returns (LinearPool) {
        (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) = getPauseConfiguration();

        LinearPool pool = UnbuttonAaveLinearPool(
            _create(
                abi.encode(
                    getVault(),
                    name,
                    symbol,
                    mainToken,
                    wrappedToken,
                    upperTarget,
                    swapFeePercentage,
                    pauseWindowDuration,
                    bufferPeriodDuration,
                    owner,
                    getPoolVersion()
                )
            )
        );

        // LinearPools have a separate post-construction initialization step: we perform it here to
        // ensure deployment and initialization are atomic.
        pool.initialize();

        // Identify the protocolId associated with this pool. We do not require that the protocolId be registered.
        emit UnbuttonAaveLinearPoolCreated(address(pool), protocolId);

        return pool;
    }

    /**
     * @notice Register an id (and name) to differentiate between multiple protocols using this factory.
     * @dev This is a permissioned function. Protocol ids cannot be deregistered.
     */
    function registerProtocolId(uint256 protocolId, string memory name) external authenticate {
        require(!_protocolIds[protocolId].registered, "Protocol ID already registered");

        _registerProtocolId(protocolId, name);
    }

    function _registerProtocolId(uint256 protocolId, string memory name) private {
        _protocolIds[protocolId] = ProtocolIdData({ name: name, registered: true });

        emit UnbuttonAaveLinearPoolProtocolIdRegistered(protocolId, name);
    }
}

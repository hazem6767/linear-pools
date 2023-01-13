import { ethers } from 'hardhat';
import { expect } from 'chai';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address';

import { bn, fp } from '@orbcollective/shared-dependencies/numbers';
import {
  deployPackageContract,
  getPackageContractDeployedAt,
  deployToken,
  setupEnvironment,
  getBalancerContractArtifact,
  MAX_UINT256,
  ZERO_ADDRESS,
} from '@orbcollective/shared-dependencies';

import { MONTH } from '@orbcollective/shared-dependencies/time';

import * as expectEvent from '@orbcollective/shared-dependencies/expectEvent';
import TokenList from '@orbcollective/shared-dependencies/test-helpers/token/TokenList';

export enum SwapKind {
  GivenIn = 0,
  GivenOut,
}

enum RevertType {
  DoNotRevert,
  NonMalicious,
  MaliciousSwapQuery,
  MaliciousJoinExitQuery,
}

async function deployBalancerContract(
    task: string,
    contractName: string,
    deployer: SignerWithAddress,
    args: unknown[]
  ): Promise<Contract> {
    const artifact = await getBalancerContractArtifact(task, contractName);
    const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, deployer);
    const contract = await factory.deploy(...args);
  
    return contract;
  }


describe('UnbuttonLinearPool', function () {
    let pool: Contract,
        vault: Contract,
        tokens: TokenList,
        mainToken: Contract,
        rebasingYieldToken: Contract,
        wrappedYieldToken: Contract;
    let poolFactory: Contract;
    let wrappedYieldTokenInstance: Contract;
    let trader: SignerWithAddress;
    let guardian: SignerWithAddress, lp: SignerWithAddress, owner: SignerWithAddress;
    let manager: SignerWithAddress;

    const POOL_SWAP_FEE_PERCENTAGE = fp(0.01);
    const BUTTONWOOD_PROTOCOL_ID = 7;
    const amplFP = (n: number) => fp(n / 10 ** 9);

    const BASE_PAUSE_WINDOW_DURATION = MONTH * 3;
    const BASE_BUFFER_PERIOD_DURATION = MONTH;

    before('Setup', async () => {
        const [deployer] = await ethers.getSigners();
        const deployerAddress = await deployer.getAddress();

        const ampl = await deploy('TestToken', {
            args: ['Mock Ampleforth', 'AMPL', 9],
        });
    })
})
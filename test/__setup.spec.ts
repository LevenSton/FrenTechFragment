
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { Signer, Wallet } from 'ethers';
import { ethers } from 'hardhat';
import {
  TomoFragmentPool,
  TomoFragmentPool__factory,
  TomoHubEntryPoint,
  TomoHubEntryPoint__factory,
  Tomo,
  Tomo__factory,
  TransparentUpgradeableProxy__factory,
  Events,
  Events__factory,
} from '../typechain-types';
import {
  computeContractAddress,
  TomoHubEntryPointState,
  revertToSnapshot,
  takeSnapshot,
} from './helpers/utils';
import { SIGN_PRIVATEKEY } from './helpers/constants';
import hre from 'hardhat'
import {utils} from 'ethers';
import { ERRORS } from './helpers/errors';
import {buildBuySeparator} from './helpers/utils'

export let accounts: Signer[];
export let deployer: Signer;
export let governance: Signer;
export let user: Signer;
export let userTwo: Signer;
export let userThree: Signer;
export let deployerAddress: string;
export let governanceAddress: string;
export let userAddress: string;
export let userTwoAddress: string;
export let userThreeAddress: string;
export let mockTomo: Tomo;
export let tomoHubEntryPointImpl: TomoHubEntryPoint;
export let tomoFragmentPool: TomoFragmentPool;
export let tomoHubEntryPointProxy: TomoHubEntryPoint;
export let eventsLib: Events;

export let abiCoder = hre.ethers.utils.defaultAbiCoder;
export let signWallet: Wallet;
export let subject = utils.keccak256(utils.toUtf8Bytes("LevenWilson"));
export let buyAmount = 200;
export let buyAmount1 = 220;
export let buyAmountForFragment = 2;
export let subject1 = utils.keccak256(utils.toUtf8Bytes("Tomo_Social"));
export const TOMO_NAME = 'Tomo';
export let currentTimestamp = parseInt((new Date().getTime() / 1000 ).toFixed(0))
export let yestoday = parseInt((new Date().getTime() / 1000 ).toFixed(0)) - 24 * 3600
export let tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600

export function makeSuiteCleanRoom(name: string, tests: () => void) {
  describe(name, () => {
    beforeEach(async function () {
      await takeSnapshot();
    });
    tests();
    afterEach(async function () {
      await revertToSnapshot();
    });
  });
}

before(async function () {
  abiCoder = ethers.utils.defaultAbiCoder;
  accounts = await ethers.getSigners();
  deployer = accounts[0];
  governance = accounts[1];
  user = accounts[2];
  userTwo = accounts[3];
  userThree = accounts[4];

  signWallet = new ethers.Wallet(SIGN_PRIVATEKEY).connect(ethers.provider);

  deployerAddress = await deployer.getAddress();
  governanceAddress = await governance.getAddress();
  userAddress = await user.getAddress();
  userTwoAddress = await userTwo.getAddress();
  userThreeAddress = await userThree.getAddress();

  //deploy mock tomo contract
  mockTomo = await new Tomo__factory(deployer).deploy(
    [signWallet.address]
  );
  
  // Here, we pre-compute the nonces and addresses used to deploy the contracts.
  const nonce = await deployer.getTransactionCount();
  // nonce + 0 is TomoHubEntryPoint impl
  // nonce + 1 is TomoFragmentPool impl
  // nonce + 2 is TomoHubEntryPoint proxy

  const tomoFragmentPoolAddress = computeContractAddress(deployerAddress, nonce + 1); //'0x' + keccak256(RLP.encode([deployerAddress, hubProxyNonce])).substr(26);
  const tomoHubEntryPointProxyAddress = computeContractAddress(deployerAddress, nonce + 2); //'0x' + keccak256(RLP.encode([deployerAddress, hubProxyNonce])).substr(26);

  tomoHubEntryPointImpl = await new TomoHubEntryPoint__factory(deployer).deploy(mockTomo.address, tomoFragmentPoolAddress);

  tomoFragmentPool = await new TomoFragmentPool__factory(deployer).deploy(tomoHubEntryPointProxyAddress, mockTomo.address);

  let data = tomoHubEntryPointImpl.interface.encodeFunctionData('initialize', [
    governanceAddress, deployerAddress
  ]);
  let proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
    tomoHubEntryPointImpl.address,
    deployerAddress,
    data
  );
  
  // Connect the hub proxy to the TomoHubEntryPoint factory and the user for ease of use.
  tomoHubEntryPointProxy = TomoHubEntryPoint__factory.connect(proxy.address, user);

  await expect(tomoHubEntryPointProxy.connect(governance).setGovernance(userAddress)).to.not.be.reverted;
  await expect(tomoHubEntryPointProxy.connect(user).setGovernance(governanceAddress)).to.not.be.reverted;
  await expect(tomoHubEntryPointProxy.connect(governance).setState(TomoHubEntryPointState.Open)).to.not.be.reverted;
  const oneEthValue = ethers.BigNumber.from('1000000000000000000');
  await expect(tomoHubEntryPointProxy.connect(governance).setMinPriceKeyCanFragment(oneEthValue)).to.not.be.reverted;

  await expect(tomoHubEntryPointProxy.connect(user).setGovernance(userAddress)).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.NOT_GOVERNANCE);
  await expect(tomoHubEntryPointProxy.connect(user).setState(TomoHubEntryPointState.Open)).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.NOT_GOVERNANCE);
  await expect(tomoHubEntryPointProxy.connect(user).setMinPriceKeyCanFragment(1000)).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.NOT_GOVERNANCE);

  expect(tomoHubEntryPointProxy).to.not.be.undefined;

  // Event library deployment is only needed for testing and is not reproduced in the live environment
  eventsLib = await new Events__factory(deployer).deploy();

  const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject, userAddress, buyAmount);
  const sig1 = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, userAddress, buyAmount1);
  const price = await mockTomo.connect(user).getBuyPriceAfterFee(subject, buyAmount);
  const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, buyAmount1);
  await expect(
      mockTomo.connect(user).buyVotePass(subject, buyAmount, [sig.v], [sig.r], [sig.s])
  ).to.be.reverted;
  await expect(
      mockTomo.connect(user).buyVotePass(subject1, buyAmount1, [sig1.v], [sig1.r], [sig1.s])
  ).to.be.reverted;

  await expect(
      mockTomo.connect(user).buyVotePass(subject, buyAmount, [sig.v], [sig.r], [sig.s], {value: price})
  ).to.not.be.reverted;
  await expect(
      mockTomo.connect(user).buyVotePass(subject1, buyAmount1, [sig1.v], [sig1.r], [sig1.s], {value: price1})
  ).to.not.be.reverted;
});

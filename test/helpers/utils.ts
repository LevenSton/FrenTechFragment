import '@nomiclabs/hardhat-ethers';
import { utils } from 'ethers';
import {
  signWallet
} from '../__setup.spec';
import { HARDHAT_CHAINID, MAX_UINT256 } from './constants';
import { hexlify, keccak256, RLP } from 'ethers/lib/utils';
import hre from 'hardhat';

export enum TomoHubEntryPointState {
  Open,
  Paused
}

export function getChainId(): number {
  return hre.network.config.chainId || HARDHAT_CHAINID;
}

export function computeContractAddress(deployerAddress: string, nonce: number): string {
  const hexNonce = hexlify(nonce);
  return '0x' + keccak256(RLP.encode([deployerAddress, hexNonce])).substr(26);
}

let snapshotId: string = '0x1';
export async function takeSnapshot() {
  snapshotId = await hre.ethers.provider.send('evm_snapshot', []);
}

export async function revertToSnapshot() {
  await hre.ethers.provider.send('evm_revert', [snapshotId]);
}

export async function buildBuySeparator(
  tomo: string,
  name: string,
  subject: string,
  userAddress: string,
  amount: number
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPermitParams(tomo, name, subject, userAddress, amount);
  return await getSig(msgParams);
}

const buildPermitParams = (
  tomo: string,
  name: string,
  subject: string,
  userAddress: string,
  amount: number
) => ({
  types: {
    Buy: [
      { name: 'subject', type: 'bytes32' },
      { name: 'sender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: tomo,
  },
  value: {
    subject: subject,
    sender: userAddress,
    amount: amount,
  },
});

async function getSig(msgParams: {
  domain: any;
  types: any;
  value: any;
}): Promise<{ v: number; r: string; s: string }> {
  const sig = await signWallet._signTypedData(msgParams.domain, msgParams.types, msgParams.value);
  return utils.splitSignature(sig);
}

/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { hexlify, keccak256, RLP } from 'ethers/lib/utils'
import {
  deployAndVerifyAndThen,
  getContractFromArtifact,
} from '../scripts/deploy-utils'

const TOMO_IMPL = "";

const deployFn: DeployFunction = async (hre) => {

  const ethers = hre.ethers;
  const { deployer } = await hre.getNamedAccounts()
  let deployerNonce = await ethers.provider.getTransactionCount(deployer);
  const TomoHubEntryPointProxyNonce = hexlify(deployerNonce + 1);
  const TomoHubEntryPointProxyAddress =
        '0x' + keccak256(RLP.encode([deployer, TomoHubEntryPointProxyNonce])).substr(26);
        
  await deployAndVerifyAndThen({
      hre,
      name: "TomoFragmentPoolImpl",
      contract: 'TomoFragmentPool',
      args: [TomoHubEntryPointProxyAddress, TOMO_IMPL],
    })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['TomoFragmentPoolImpl']

export default deployFn

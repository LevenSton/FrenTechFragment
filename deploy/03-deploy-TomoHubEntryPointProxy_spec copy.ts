/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
  getContractFromArtifact,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {
  const TomoHubEntryPointImpl = await getContractFromArtifact(
    hre,
    "TomoHubEntryPointImpl"
  )
  const { deployer,  governance} = await hre.getNamedAccounts()

  let data = TomoHubEntryPointImpl.interface.encodeFunctionData('initialize', [
    governance, deployer
  ]);

  await deployAndVerifyAndThen({
    hre,
    name: "TomoHubEntryPointProxy",
    contract: 'TransparentUpgradeableProxy',
    args: [TomoHubEntryPointImpl.address, deployer, data],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['TomoHubEntryPointProxy']

export default deployFn

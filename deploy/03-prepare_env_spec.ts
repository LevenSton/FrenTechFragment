/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  getContractFromArtifact
} from '../scripts/deploy-utils'
import { BigNumber} from 'ethers';

const deployFn: DeployFunction = async (hre) => {

  const {governance} = await hre.getNamedAccounts()

  const TomoHubEntryPointProxy = await getContractFromArtifact(
    hre,
    "TomoHubEntryPointProxy",
    {
      iface: 'TomoHubEntryPoint',
      signerOrProvider: governance,
    }
  )
  const MIN_PRICE_FRAGMENT = BigNumber.from(1000000000000000000n);
  await TomoHubEntryPointProxy.setMinPriceKeyCanFragment(MIN_PRICE_FRAGMENT);
  await TomoHubEntryPointProxy.setState(0);
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['PrepareEnv']

export default deployFn

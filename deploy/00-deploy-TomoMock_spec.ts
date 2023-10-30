/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
  isHardhatNode,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {

  if((await isHardhatNode(hre)))
  {
    const { deployer } = await hre.getNamedAccounts()
    await deployAndVerifyAndThen({
      hre,
      name: "Tomo",
      contract: 'Tomo',
      args: [[deployer]],
    })
  } 
}

deployFn.tags = ['Tomo']

export default deployFn

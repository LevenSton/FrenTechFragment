/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { hexlify, keccak256, RLP } from 'ethers/lib/utils';
import {
  deployAndVerifyAndThen,
  getContractFromArtifact,
  isHardhatNode,
  getTomoImplAddr
} from '../scripts/deploy-utils';

const deployFn: DeployFunction = async (hre) => {
    const ethers = hre.ethers;
    const { deployer } = await hre.getNamedAccounts()
    let deployerNonce = await ethers.provider.getTransactionCount(deployer);
    const tomoFragmentPoolNonce = hexlify(deployerNonce + 1);
    const tomoFragmentPoolImplAddress =
        '0x' + keccak256(RLP.encode([deployer, tomoFragmentPoolNonce])).substr(26);

    
    let TOMO_IMPL = await getTomoImplAddr(hre);
    if((await isHardhatNode(hre)))
    {
        const TOMO = await getContractFromArtifact(
            hre,
            "Tomo"
        )
        TOMO_IMPL = TOMO.address
    }
    await deployAndVerifyAndThen({
        hre,
        name: "TomoHubEntryPointImpl",
        contract: 'TomoHubEntryPoint',
        args: [TOMO_IMPL, tomoFragmentPoolImplAddress],
    })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['TomoHubEntryPointImpl']

export default deployFn

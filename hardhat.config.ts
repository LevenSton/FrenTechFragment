import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv'
import '@primitivefi/hardhat-dodoc'
import 'hardhat-deploy'

dotenv.config()

const deployer = process.env.DEPLOY_PRIVATE_KEY || '0x' + '11'.repeat(32)
const governance = process.env.GOVERNANCE_PRIVATE_KEY || '0x' + '11'.repeat(32)

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.20',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
            details: {
              yul: true,
            },
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      gas: 16000000,
    },
    lineaTest: {
      chainId: 59140,
      url: process.env.LINEA_TEST_RPC_URL || '',
      accounts: [deployer, governance],
      gasPrice: 1000000000,
    },
    linea: {
      chainId: 59144,
      url: process.env.LINEA_RPC_URL || '',
      accounts: [deployer, governance],
      gasPrice: 1000000000,
    },
  },
  paths: {
    deploy: './deploy',
    deployments: './deployments',
  },
  dodoc: {
    runOnCompile: true,
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    governance: {
      default: 1,
    }
  },
};

export default config;

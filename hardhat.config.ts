import dotenv from "dotenv";
dotenv.config();

import { HardhatUserConfig } from "hardhat/config";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter";
import "solidity-coverage";

const { ALCHEMY_API_URL_STG, ALCHEMY_API_URL, PRIVATE_KEY, ETHERSCAN_API_KEY, COINMARKETCAP_API_KEY } = process.env;

const config: HardhatUserConfig = {
   solidity: {
      version: "0.8.10",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
    defaultNetwork: "rinkeby",
    networks: {
      hardhat: {
        chainId: 1337
      },
      mainnet: {
        url: ALCHEMY_API_URL,
        accounts: [`0x${PRIVATE_KEY}`],
      },
      rinkeby: {
        url: ALCHEMY_API_URL_STG,
        accounts: [`0x${PRIVATE_KEY}`],
      },
      coverage: {
        url: "http://127.0.0.1:8555"
      }
    },
    etherscan: {
      apiKey: ETHERSCAN_API_KEY,
    },
    gasReporter: {
      currency: 'USD',
      enabled: true,
      coinmarketcap: COINMARKETCAP_API_KEY,
      gasPrice: 50
    },
    typechain: {
      outDir: "types",
      target: "ethers-v5"
    }
}

export default config;
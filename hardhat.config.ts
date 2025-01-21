import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-ignition-ethers";
import "hardhat-gas-reporter";
import testConfig from "./test/utils/config";
import "@nomicfoundation/hardhat-ignition-ethers";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: { viaIR: true },
  },
  networks: {
    testnet: {
      url: testConfig.rpc,
      accounts: testConfig.accounts,
      chainId: 8882,
    },
  },
  defaultNetwork: "testnet",
  mocha: {
    timeout: 10 * 60 * 1000,
  },
  gasReporter: {
    enabled: true,
  },
};

export default config;

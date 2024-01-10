require("@matterlabs/hardhat-zksync-solc");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    defaultNetwork: "mumbai",
   networks: {
    hardhat: {},
    mumbai: {
      url: 'https://rpc.ankr.com/polygon_mumbai',
      accounts: ['${process.env.PRIVATE_KEY}'],
    },
  },
  paths: {
    artifacts: "./artifacts-zk",
    cache: "./cache-zk",
    sources: "./contracts",
    tests: "./test",
  },

    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};

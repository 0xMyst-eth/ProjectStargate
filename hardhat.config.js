require("@shardlabs/starknet-hardhat-plugin");
require("@nomiclabs/hardhat-ethers");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: '0.8.4',
  starknet: {
    // dockerizedVersion: "0.8.1-arm", // alternatively choose one of the two venv options below
    // uses (my-venv) defined by `python -m venv path/to/my-venv`
    // venv: "path/to/my-venv",

    // uses the currently active Python environment (hopefully with available Starknet commands!)
    venv: "active",
    network: "devnet",
    wallets: {
      OpenZeppelin: {
        accountName: "OpenZeppelin",
        modulePath: "starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount",
        accountPath: "~/.starknet_accounts"
      }
    }
  },
  networks: {
    devnet: {
      url: "http://127.0.0.1:5050"
    },
  },
};


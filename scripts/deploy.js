// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const axios = require("axios");
const { ethers } = require("hardhat");


const gasUrls = {
  polygon:  'https://gasstation.polygon.technology/v2', // Polygon Pos Mainet
  mumbai: 'https://gasstation-testnet.polygon.technology/v2' // Polygon Mumbai
}

const getFeeOption = async () => {
  const data =  (await axios(gasUrls[hre.network.name])).data
  return {
    maxFeePerGas: ethers.parseUnits(Math.ceil(data.fast.maxFee).toString(), 'gwei'),
    maxPriorityFeePerGas: ethers.parseUnits(Math.ceil(data.fast.maxPriorityFee).toString(), 'gwei')
  }
}

//wait for n blocks
const waitBlocks = async (n) => {
  const provider = ethers.provider;
  const currentBlock = await provider.getBlockNumber()
  const targetBlock = currentBlock + n
  return new Promise((resolve, reject) => {
    provider.on("block", (blockNumber) => {
      console.log("blockNumber: ", blockNumber)
      if (blockNumber == targetBlock) {
        provider.removeAllListeners("block");
        resolve();
      }
    })
  })
}

async function main() {

  const Contract = await ethers.getContractFactory("ViewingDay");
  Contract.runner.provider.getFeeData = async () => await getFeeOption()
  const [signer] = await ethers.getSigners();
  signer.provider.getFeeData = async () => await getFeeOption();
  Contract.connect(signer);

  console.log('network: ', hre.network.name);
  const contract = await Contract.deploy(signer.address);
  console.log('signer addr : ', signer.address)
  const addr = await contract.getAddress();
  console.log("Token address:", addr);
  await waitBlocks(5)
  await hre.run("verify:verify", { address: addr, constructorArguments: [signer.address] });

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

//npx hh run scripts/deploy.js --network mumbai



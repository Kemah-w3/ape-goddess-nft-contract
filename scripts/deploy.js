const { ethers } = require("hardhat")


async function main() {
  const apeGoddessContractFactory = await ethers.getContractFactory("ApeGoddess")
  const apeGoddessContract = await apeGoddessContractFactory.deploy()
  await apeGoddessContract.deployed()

  console.log("ApeGoddess contract address is: ", apeGoddessContract.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
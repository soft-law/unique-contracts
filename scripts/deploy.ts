import { ethers } from "hardhat";
// import { parseEther } from "ethers";
// import { Address } from "@unique-nft/utils";
// import { expect } from "chai";
import testConfig from "./utils/config";

async function main() {
  // Deploy SoftlawContract Contract library
  const Softlaw = await ethers.getContractFactory("Softlaw");
  const converter = await Softlaw.deploy();
  await converter.waitForDeployment();
  console.log("Softlaw deployed to:", await converter.getAddress());

  // Deploy Softlaw with library
  const SoftlawContract = await ethers.getContractFactory("SoftlawContract", {
    libraries: {
      Softlaw: await converter.getAddress(),
    },
  });

  const initialBalance = ethers.parseEther("0.1");
  const softlaw = await SoftlawContract.deploy({ value: initialBalance });
  await softlaw.waitForDeployment();

  console.log("SoftlawContract deployed to:", await softlaw.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

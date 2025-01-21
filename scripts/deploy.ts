import { ethers } from "hardhat";
import { parseEther } from "ethers";
import { Address } from "@unique-nft/utils";

async function main(): Promise<void> {
  try {
    const [minterOwner] = await ethers.getSigners();
    console.log("Deploying contracts with account:", minterOwner.address);

    const balanceMinterOwner = await ethers.provider.getBalance(minterOwner);
    console.log("Account balance:", ethers.formatEther(balanceMinterOwner));

    // Verify balance
    if (balanceMinterOwner < parseEther("100")) {
      throw new Error("Insufficient balance for deployment");
    }

    // Deploy Softlaw
    console.log("\nDeploying Softlaw...");
    const Softlaw = await ethers.getContractFactory("Softlaw");

    const softlaw = await Softlaw.connect(minterOwner).deploy({
      gasLimit: 3_000_000,
      value: parseEther("100"),
    });

    await softlaw.waitForDeployment();
    const softlawAddress = await softlaw.getAddress();

    // Log addresses in both formats
    console.log("\nDeployment Summary: ");
    console.log("Softlaw (EVM):", softlawAddress);
    console.log(
      "Softlaw (SUB):",
      Address.mirror.ethereumToSubstrate(softlawAddress),
    );

    // Log final balance and costs
    const finalBalance = await ethers.provider.getBalance(minterOwner);
    console.log("\nFinal balance:", ethers.formatEther(finalBalance));
    console.log(
      "Deploy cost:",
      ethers.formatEther(balanceMinterOwner - finalBalance),
    );
  } catch (error) {
    console.error("\nDeployment Error:");
    console.error("-----------------");
    if (error instanceof Error) {
      console.error("Message:", error.message);
    } else {
      console.error("Unknown error:", error);
    }
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });

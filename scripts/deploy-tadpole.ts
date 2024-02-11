import { ethers } from "hardhat";

async function main() {
    console.log("Starting $TADPOLE deployment...");
    const factory = await ethers.getContractFactory("Tadpole");
    const [owner] = await ethers.getSigners();
    console.log("\nDeployment Owner: ", owner.address);

    const contract = (await factory.deploy("0x7A405A70575714D74A1fA0B860730CF7456e6eBB", 50, 50));
    console.log("\nContract Address: ", contract.address);

    await contract.deployed();
    console.log("\nContract deployed...");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    });
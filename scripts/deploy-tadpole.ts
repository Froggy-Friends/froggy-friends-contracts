import { ethers, run, network } from "hardhat";

function sleep(ms: number) {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    })
}

async function main() {
    console.log("Starting $TADPOLE deployment...");
    const factory = await ethers.getContractFactory("Tadpole");
    const [owner] = await ethers.getSigners();
    console.log("\nDeployment Owner: ", owner.address);

    const contract = (await factory.deploy("0x6b01aD68aB6F53128B7A6Fe7E199B31179A4629a", 10000, 10000));
    console.log("\nContract Address: ", contract.address);

    await contract.deployed();
    console.log("\nContract deployed...");

    await contract.deployTransaction.wait(5);
    console.log("\nContract deployed with 5 confirmations waiting 60 seconds to verify...");

    await sleep(60000);

    console.log("\nPublishing and verifying code to Etherscan...");
    await run("verify:verify",
        {
            address: contract.address,
            constructorArguments: ["0x6b01aD68aB6F53128B7A6Fe7E199B31179A4629a", 10000, 10000]
        }
    );
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    });
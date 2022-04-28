import { ethers, run } from "hardhat";

interface ContractParams {
  name: string;
  symbol: string;
}

function sleep(ms: number) {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    })
}

async function main() {
    console.log("Starting deployment...");
    const factory = await ethers.getContractFactory("Ribbit");
    const [owner] = await ethers.getSigners();
    console.log("\nDeployment Owner: ", owner.address);

    const { name, symbol } = getContractParams();
    const contract = (await factory.deploy(name, symbol));
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
            constructorArguments: [name, symbol]
        }
    );
}

function getContractParams(): ContractParams {
  return {
    name: "Ribbit",
    symbol: "RIBBIT"
  }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    });
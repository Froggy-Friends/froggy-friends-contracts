import { ethers, run, network } from "hardhat";

interface ContractParams {
    baseUrl: string;
}

function sleep(ms: number) {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    })
}

async function main() {
    console.log("Starting deployment...");
    const factory = await ethers.getContractFactory("FroggyFriends");
    const [owner] = await ethers.getSigners();
    console.log("\nDeployment Owner: ", owner.address);

    const { baseUrl } = getContractParams(network.name);
    const contract = (await factory.deploy(baseUrl));
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
            constructorArguments: [baseUrl]
        }
    );
}

function getContractParams(network: string): ContractParams {
    if (network == "mainnet") {
        return {
            baseUrl: ""
        }
    } else {
        return {
            baseUrl: ""
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    });
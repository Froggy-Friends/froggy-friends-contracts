import { ethers, run, network } from "hardhat";

interface ContractParams {
  froggyAddress: string;
}

function sleep(ms: number) {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    })
}

async function main() {
    console.log("Starting deployment...");
    const factory = await ethers.getContractFactory("StakeFroggies");
    const [owner] = await ethers.getSigners();
    console.log("\nDeployment Owner: ", owner.address);

    const { froggyAddress } = getContractParams(network.name);
    const contract = (await factory.deploy(froggyAddress));
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
            constructorArguments: [froggyAddress]
        }
    );
}

function getContractParams(network: string): ContractParams {
  if (network == "mainnet") {
      return {
          froggyAddress: "0x29652C2e9D3656434Bc8133c69258C8d05290f41",
      }
  } else {
      return {
          froggyAddress: "0xF47E8A340672Dacb10Da0f677632a694a96E9CD0"
      }
  }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    });
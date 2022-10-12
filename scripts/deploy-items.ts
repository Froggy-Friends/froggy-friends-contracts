import { ethers, run, network } from "hardhat";

interface ContractParams {
  name: string;
  symbol: string;
  baseUrl: string;
  contractUrl: string;
  ribbitAddress: string;
  froggyAddress: string;
}

function sleep(ms: number) {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    })
}

async function main() {
    console.log("Starting deployment...");
    const factory = await ethers.getContractFactory("RibbitItem");
    const [owner] = await ethers.getSigners();
    console.log("\nDeployment Owner: ", owner.address);

    const { name, symbol, baseUrl, contractUrl, ribbitAddress, froggyAddress } = getContractParams(network.name);
    const contract = (await factory.deploy(name, symbol, baseUrl, contractUrl, ribbitAddress, froggyAddress));
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
            constructorArguments: [name, symbol, baseUrl, contractUrl, ribbitAddress, froggyAddress]
        }
    );
}

function getContractParams(network: string): ContractParams {
  if (network === 'mainnet') {
    return {
      name: "Ribbit Item",
      symbol: "RIBBIT ITEM",
      baseUrl: "https://api.froggyfriendsnft.com/items/",
      contractUrl: "contract/metadata",
      ribbitAddress: "0x46898f15F99b8887D87669ab19d633F579939ad9",
      froggyAddress: "0x8F7b5f7845224349ae9Ae45B400EBAE0051fCD9d" // use staking address for collabBuy verification
    }
  } else {
    return {
      name: "Ribbit Item",
      symbol: "RIBBIT ITEM",
      baseUrl: "https://api.froggyfriendsnft.com/items/",
      contractUrl: "contract/metadata",
      ribbitAddress: "0xF47E8A340672Dacb10Da0f677632a694a96E9CD0",
      froggyAddress: "0xE5413Ccf0D90c0fA594bABa2a858cb93675da2Ee" // use staking address for collabBuy verification
    }
  }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    });
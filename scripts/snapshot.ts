import fs from 'fs';
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const json = require('../artifacts/contracts/FroggyFriends.sol/FroggyFriends.json');
const web3 = createAlchemyWeb3(`${process.env.ALCHEMY_API_URL}`);
const contract = new web3.eth.Contract(json.abi, "0x29652C2e9D3656434Bc8133c69258C8d05290f41");

async function getHolders() {
  const totalSupply = await contract.methods.totalSupply().call();
  console.log("total supply: ", totalSupply);

  const holders: any = {};

  for (let i = 4076; i < totalSupply; i++) {
    let owner = await contract.methods.ownerOf(i).call();
    owner = owner.toLowerCase();
    console.log("owner: " + i + " " + owner);

    if (holders[owner]) {
      holders[owner]++;
    } else {
      holders[owner] = 1;
    }
  }

  const flat = JSON.stringify(holders);
  fs.writeFile('./snapshot.json', flat, { flag: 'w'}, function (err) {
    if (err) {
      console.log("snapshot error: ", err);
    }
  })
}

getHolders();
import fs from 'fs';
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const json = require('../artifacts/contracts/FroggyFriends.sol/FroggyFriends.json');
const web3 = createAlchemyWeb3(`${process.env.ALCHEMY_API_URL}`);
const contract = new web3.eth.Contract(json.abi, "0x29652C2e9D3656434Bc8133c69258C8d05290f41");

async function getOwnerTokens(account: string) {
  const balanceOf = await contract.methods.balanceOf(account).call();
  console.log("balance of : ", balanceOf);

  const ownerInfo: { owner: string, tokens: number[]} = {
    owner: account,
    tokens: []
  };
  for (let i = 0; i < balanceOf; i++) {
    let tokenId: number = await contract.methods.tokenOfOwnerByIndex(account, i).call();
    console.log("token id: ", tokenId);
    ownerInfo.tokens.push(+tokenId);
  }

  fs.writeFile('./ownerTokens.json', JSON.stringify(ownerInfo), { flag: 'w'}, function (err) {
    if (err) {
      console.log("owner snapshot error: ", err);
    }
  })
}

getOwnerTokens("0x88f09bdc8e99272588242a808052eb32702f88d0");
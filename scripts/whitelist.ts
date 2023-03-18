import MerkleTree from "merkletreejs";
import { utils } from "ethers";
const { keccak256 } = utils;
import { holders } from './holders';

console.log("total holders: ", holders.length);

let hashedWallets = [];

for (const wallet of holders) {
  const hashed = keccak256(wallet);
  hashedWallets.push(hashed);
}

let whitelist = new MerkleTree(hashedWallets, keccak256, { sortPairs: true });

console.log("Holders root: ", whitelist.getHexRoot());
let proof = whitelist.getHexProof(keccak256('0x6b01aD68aB6F53128B7A6Fe7E199B31179A4629a'));
console.log("Holder proof: ", proof);
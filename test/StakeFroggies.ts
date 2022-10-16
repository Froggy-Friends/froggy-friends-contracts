import { Ribbit } from './../types/Ribbit';
import { RibbitItem } from './../types/RibbitItem';
import { FroggyFriends } from './../types/FroggyFriends';
import { StakeFroggies } from './../types/StakeFroggies';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { FriendPairing } from './../types/FriendPairing';
import { ethers } from "hardhat";
import { expect } from 'chai';
import keccak256 from 'keccak256';
import MerkleTree from 'merkletreejs';

function generateStakingTiers(rarityBand: any): string[] {
  let rarityAmount: string[] = [];
  for (let i = 0; i < rarityBand.common.length; i++) {
    let q = '' + rarityBand.common[i] + 20
    rarityAmount.push(q)
  }
  for (let i = 0; i < rarityBand.uncommon.length; i++) {
    let q = '' + rarityBand.uncommon[i] + 30
    rarityAmount.push(q)
  }
  for (let i = 0; i < rarityBand.rare.length; i++) {
    let q = '' + rarityBand.rare[i] + 40
    rarityAmount.push(q)
  }
  for (let i = 0; i < rarityBand.legendary.length; i++) {
    let q = '' + rarityBand.legendary[i] + 75
    rarityAmount.push(q)
  }
  for (let i = 0; i < rarityBand.epic.length; i++) {
    let q = '' + rarityBand.epic[i] + 150
    rarityAmount.push(q)
  }
  return rarityAmount;
}


describe("Friend Pairing", async () => {
  let friendPairing: FriendPairing;
  let stakeFroggies: StakeFroggies;
  let ribbit: Ribbit;
  let ribbitItems: RibbitItem;
  let froggyFriends: FroggyFriends;
  let owner: SignerWithAddress;
  let acc2: SignerWithAddress;
  let acc3: SignerWithAddress;
  let tree: MerkleTree;
  let root;
  let rarityAmount;
  let rarityBand;

  before(async() => {
    rarityBand = {
      "common": [3, 4],
      "uncommon": [5, 6],
      "rare": [7, 8],
      "legendary": [9, 10],
      "epic": [11, 12]
    }
    rarityAmount = generateStakingTiers(rarityBand);
    const leaves = rarityAmount.map(x => keccak256(x));
    tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    root = '0x'+tree.getRoot().toString('hex');

    [owner, acc2, acc3] = await ethers.getSigners();
    let frogFactory = await ethers.getContractFactory("FroggyFriends");
    let stakingFactory = await ethers.getContractFactory("StakeFroggies");
    let ribbitFactory = await ethers.getContractFactory("Ribbit");
    let ribbitItemFactory = await ethers.getContractFactory("RibbitItem");
    let pairingFactory = await ethers.getContractFactory("FriendPairing");

    // deploy frogs
    froggyFriends = (await frogFactory.deploy()) as FroggyFriends;
    await froggyFriends.deployed();

    // deploy ribbit token
    ribbit = (await ribbitFactory.deploy("Ribbit", "Ribit")) as Ribbit;
    await ribbit.deployed();

    // deploy staking froggies
    stakeFroggies = (await stakingFactory.deploy(froggyFriends.address)) as StakeFroggies;
    await stakeFroggies.deployed();
    await stakeFroggies.setRibbitAddress(ribbit.address);
    await ribbit.setApprovedContractAddress(stakeFroggies.address);

    // deploy ribbit items
    ribbitItems = (await ribbitItemFactory.deploy("RibbitItems", "RibbitItems", "", "", ribbit.address, froggyFriends.address)) as RibbitItem;
    await ribbitItems.deployed();

    friendPairing = (await pairingFactory.deploy(stakeFroggies.address)) as FriendPairing;
    await friendPairing.deployed();
  });

  it("Creates contract addresses", () => {
    expect(froggyFriends.address);
    expect(ribbit.address);
    expect(stakeFroggies.address);
    expect(ribbitItems.address);
    expect(friendPairing.address);
  });
  
});
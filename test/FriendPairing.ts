import { RibbitItem } from './../types/RibbitItem';
import { FroggyFriends } from './../types/FroggyFriends';
import { StakeFroggies } from './../types/StakeFroggies';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { FriendPairing } from './../types/FriendPairing';
import { ethers } from "hardhat";

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
  let ribbitItems: RibbitItem;
  let froggyFriends: FroggyFriends;
  let owner: SignerWithAddress;
  let acc2: SignerWithAddress;
  let rarityAmount;
  let rarityBand;

  before(() => {
    rarityBand = {
      "common": [3, 4],
      "uncommon": [5, 6],
      "rare": [7, 8],
      "legendary": [9, 10],
      "epic": [11, 12]
    }
    rarityAmount = generateStakingTiers(rarityBand);
  })

  beforeEach(async() => {
    [owner, acc2] = await ethers.getSigners();
    let frogFactory = await ethers.getContractFactory("FroggyFriends");
    let stakingFactory = await ethers.getContractFactory("StakeFroggies");
    let ribbitItemFactory = await ethers.getContractFactory("RibbitItem");
    let pairingFactory = await ethers.getContractFactory("FriendPairing");
    froggyFriends = (await frogFactory.deploy()) as FroggyFriends;
    stakeFroggies = (await stakingFactory.deploy()) as StakeFroggies;
    ribbitItems = (await ribbitItemFactory.deploy()) as RibbitItem;
    friendPairing = (await pairingFactory.deploy()) as FriendPairing;
    await froggyFriends.deployed();
    await stakeFroggies.deployed();
    await ribbitItems.deployed();
    await friendPairing.deployed();
  })
  
});
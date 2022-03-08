import { parseEther } from "@ethersproject/units";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BytesLike, ContractFactory } from "ethers";
import { ethers } from "hardhat";
import { FroggyFriends } from './../types/FroggyFriends';


describe("Froggy Friends", async () => {
  let factory: ContractFactory;
  let contract: FroggyFriends;
  let owner: SignerWithAddress;
  let acc2: SignerWithAddress;
  let acc3: SignerWithAddress;
  let pond = 4444;;
  let adopt = 2;
  let froggyUrl = "https://api.froggyfriendsmint.com";
  let adoptionFee = "0.03";
  const founder = "0x3E7BBe45D10B3b92292F150820FC0E76b93Eca0a";
  const projectManager = "0x818867901f28de9A77117e0756ba12E90B957242";
  const developer = "0x1AF8c7140cD8AfCD6e756bf9c68320905C355658";
  const community = "0xc4e3ceB4D732b1527Baf47B90c3c479AdC02e39A";

  async function mint(user: SignerWithAddress, froggies: number) {
    const value = parseEther(adoptionFee).mul(froggies);
    await contract.connect(user).publicAdopt(froggies, { value: value });
  }

  async function mintFroggylist(user: SignerWithAddress, froggies: number, proof: BytesLike[]) {
    const value = parseEther(adoptionFee).mul(froggies);
    await contract.connect(user).froggylistAdopt(froggies, proof, { value: value });
  }

  beforeEach(async () => {
    [owner, acc2, acc3] = await ethers.getSigners();
    factory = await ethers.getContractFactory("FroggyFriends");
    contract = (await factory.deploy(froggyUrl)) as FroggyFriends;
    await contract.deployed();
  });

  describe("public adopt", async () => {

  });

  describe("froggylist adopt", async () => {

  });

  describe("set methods", async () => {

  });

  describe("withdraw", async () => {

  });

  describe("token uri", async () => {

  });
});
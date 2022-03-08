import { parseEther } from "@ethersproject/units";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BytesLike, ContractFactory } from "ethers";
import { ethers } from "hardhat";
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";
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
  let froggyList: MerkleTree;
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

  function hash(account: string) {
    return Buffer.from(ethers.utils.solidityKeccak256(['uint256'], [account]).slice(2), 'hex');
  }

  before(async () => {
    [owner, acc2, acc3] = await ethers.getSigners();
    let froggylist = [owner.address, acc2.address];
    froggyList = new MerkleTree(froggylist.map(acc => hash(acc)), keccak256, { sortPairs: true });
  });

  beforeEach(async () => {
    [owner, acc2, acc3] = await ethers.getSigners();
    factory = await ethers.getContractFactory("FroggyFriends");
    contract = (await factory.deploy(froggyUrl)) as FroggyFriends;
    await contract.deployed();
  });

  describe("public adopt", async () => {
    it("public adopting off", async () => {
    
    });

    it("adopt limit per wallet", async () => {

    });

    it("insufficient funds", async () => {

    });

    it("pond is full", async () => {

    });

  });

  describe("froggylist adopt", async () => {
    it("froggylist adopting off", async () => {
    
    });

    it("not on froggylist", async () => {

    });

    it("adopt limit per wallet", async () => {

    });

    it("insufficient funds", async () => {

    });

    it("pond is full", async () => {

    });
  });

  describe("set methods", async () => {

  });

  describe("withdraw", async () => {

  });

  describe("token uri", async () => {

  });
});
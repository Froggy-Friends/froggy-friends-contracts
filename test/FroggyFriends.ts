import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ContractFactory } from "ethers";
import { FroggyFriends } from './../types/FroggyFriends';


describe("Froggy Friends", async () => {
  let factory: ContractFactory;
  let contract: FroggyFriends;
  let owner: SignerWithAddress;
  let acc2: SignerWithAddress;
  let acc3: SignerWithAddress;
  let pond = 4444;;
  let adopt = 3;
});
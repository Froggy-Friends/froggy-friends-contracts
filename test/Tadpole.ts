import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, ContractFactory } from "ethers";
import { ethers } from "hardhat";
import { Tadpole } from "../types/Tadpole";


describe("Tadpole", async () => {
    let factory: ContractFactory;
    let contract: Tadpole;
    let owner: SignerWithAddress;
    let acc2: SignerWithAddress;
    let acc3: SignerWithAddress;
    let tadpolePreview = "https://froggyfriends.mypinata.cloud/ipfs/QmbwoXXypGGFvfH3DKn7ob4DFmdpGrieysgWpvBtKvm3Kp";
    let tadpoleUrl = "https://api.froggyfriends.io/tadpole/";

    beforeEach(async () => {
        [owner, acc2, acc3] = await ethers.getSigners();
        factory = await ethers.getContractFactory("Tadpole");
        contract = (await factory.deploy(owner.address,)) as Tadpole;
        await contract.deployed();
        console.log("contract deployed: ", contract.address);
    });

    describe("Transfer", async () => {

        it("should transfer from", async () => {
            await contract.transferFrom(owner.address, acc2.address, BigNumber.from(100));
            const balance = await contract.balanceOf(acc2.address);
            console.log("balance: ", balance);
            expect(balance.toNumber()).equals(100);
        });
    });

    describe("token uri", async () => {


        it("pre reveal", async () => {
            await contract.setTadpoleUrl(tadpolePreview);
            const tokenUri = await contract.tokenURI(0);
            console.log("pre reveal tokenuri: ", tokenUri);
            expect(tokenUri).equals(tadpolePreview);
        });

        it("post reveal", async () => {
            await contract.setTadpoleUrl(tadpoleUrl);
            await contract.setRevealed(true);
            const tokenUri = await contract.tokenURI(0);
            console.log("post reveal tokenuri: ", tokenUri);
            expect(tokenUri).equals(`${tadpoleUrl}0`);
        });
    });
});
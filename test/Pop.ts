import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { randomBytes } from 'crypto';
import { expect } from "chai";
import { ethers } from "hardhat";

enum BurnAuth {
  IssuerOnly,
  OwnerOnly,
  Both,
  Neither
}

describe("Pop", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploySoulbindFixture() {

    // Contracts are deployed using the first signer/account by default
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();

    const burnAuth = BurnAuth.Both;

    const Pop = await ethers.getContractFactory("Pop");
    const pop = await Pop.deploy();

    return { pop, burnAuth, owner, addr1, addr2, addr3 };
  }


  describe("Create", function () {

    describe("createPromise", function () {
      it("should create a promise class", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deploySoulbindFixture);
        const tokenUri = '12345';
        const promiseCreation = {
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [addr2.address, addr3.address],
          _burnAuth: ethers.BigNumber.from(BurnAuth.Both),
          _tokenUri: tokenUri,
        }

        console.log(promiseCreation);


        await pop.connect(addr1).createPromise(promiseCreation);

        const promise = await pop.promises(ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)));
        expect(promise.creator).to.equal(addr1.address);
      });

      it("should NOT create dupe promise classes", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deploySoulbindFixture);
        const tokenUri = '12345';
        const promiseCreation = {
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [addr2.address, addr3.address],
          _burnAuth: ethers.BigNumber.from(BurnAuth.Both),
          _tokenUri: tokenUri,
        }

        console.log(promiseCreation);


        await pop.connect(addr1).createPromise(promiseCreation);

        const promise = await pop.promises(ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)));
        expect(promise.creator).to.equal(addr1.address);

        await expect(pop.connect(addr1).createPromise(promiseCreation)).to.revertedWith('Promise exists');
      });
    });
  });
});

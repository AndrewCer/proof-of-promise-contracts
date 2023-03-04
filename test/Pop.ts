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
  async function deployPopFixture() {

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
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);
        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.Both),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        const promise = await pop.promises(ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)));
        expect(promise.creator).to.equal(addr1.address);
      });

      it("should NOT create dupe promise classes", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);
        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.Both),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [addr2.address, addr3.address],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        const promise = await pop.promises(ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)));

        expect(promise.creator).to.equal(addr1.address);

        await expect(pop.connect(addr1).createPromise(promiseCreation)).to.revertedWith('Promise exists');
      });
    });
  });

  describe("Sign", function () {

    describe("signPromise", function () {
      it("should sign a non restricted promise", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);
        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.Both),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        await pop.connect(addr2).signPromise(promiseCreation.promiseHash);

        expect(await pop.ownerOf(1)).to.equal(addr2.address);
      });

      it("should sign a restricted promise", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);
        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.Both),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [addr2.address, addr3.address],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        await pop.connect(addr2).signPromise(promiseCreation.promiseHash);

        expect(await pop.ownerOf(1)).to.equal(addr2.address);
      });

      it("should not sign a restricted promise if receiver is not found", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);
        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.Both),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [addr2.address],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        await expect(pop.connect(addr3).signPromise(promiseCreation.promiseHash)).to.revertedWith('Not on receivers list');
      });
    });
  });

  describe("Burn", function () {

    describe("IssuerOnly", function () {
      it("should only burn if issuer requests it", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);

        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.IssuerOnly),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        await pop.connect(addr2).signPromise(promiseCreation.promiseHash);

        expect(await pop.ownerOf(1)).to.equal(addr2.address);
        expect(await pop.burnAuth(1)).to.equal(BurnAuth.IssuerOnly);

        await expect(pop.connect(addr2).burnToken(1, promiseCreation.promiseHash)).to.revertedWith('Only issuer may burn');
        await pop.connect(addr1).burnToken(1, promiseCreation.promiseHash);
        await expect(pop.ownerOf(1)).to.revertedWith('ERC721: invalid token ID');
      });
    });

    describe("OwnerOnly", function () {
      it("should only burn if owner requests it", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);

        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.OwnerOnly),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        await pop.connect(addr2).signPromise(promiseCreation.promiseHash);

        expect(await pop.ownerOf(1)).to.equal(addr2.address);
        expect(await pop.burnAuth(1)).to.equal(BurnAuth.OwnerOnly);

        await expect(pop.connect(addr1).burnToken(1, promiseCreation.promiseHash)).to.revertedWith('Only owner may burn');
        await pop.connect(addr2).burnToken(1, promiseCreation.promiseHash);
        await expect(pop.ownerOf(1)).to.revertedWith('ERC721: invalid token ID');
      });
    });
    xdescribe("Both", function () {
      it("should burn for either owner or issuer", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);

        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.Both),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        await pop.connect(addr2).signPromise(promiseCreation.promiseHash);

        expect(await pop.ownerOf(1)).to.equal(addr2.address);
        expect(await pop.burnAuth(1)).to.equal(BurnAuth.OwnerOnly);

        await pop.connect(addr2).burnToken(1, promiseCreation.promiseHash);
        await pop.connect(addr2).signPromise(promiseCreation.promiseHash);
        await pop.connect(addr1).burnToken(2, promiseCreation.promiseHash)
        await expect(pop.ownerOf(1)).to.revertedWith('ERC721: invalid token ID');
        await expect(pop.ownerOf(2)).to.revertedWith('ERC721: invalid token ID');
      });
    });
    describe("Neither", function () {
      it("should never burn", async function () {
        const { pop, addr1, addr2, addr3 } = await loadFixture(deployPopFixture);

        const tokenUri = '12345';
        const promiseCreation = {
          burnAuth: ethers.BigNumber.from(BurnAuth.Neither),
          promiseHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(`${tokenUri}:${addr1.address}`)),
          receivers: [],
          tokenUri: tokenUri,
        }

        await pop.connect(addr1).createPromise(promiseCreation);

        await pop.connect(addr2).signPromise(promiseCreation.promiseHash);

        expect(await pop.ownerOf(1)).to.equal(addr2.address);
        expect(await pop.burnAuth(1)).to.equal(BurnAuth.Neither);

        await expect(pop.connect(addr1).burnToken(1, promiseCreation.promiseHash)).to.revertedWith('Burn not allowed');
      });
    });
  });
});

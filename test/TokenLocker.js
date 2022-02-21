const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenLocker", function () {
  let mirkoToken;
  let tokenLocker;

  beforeEach(async function () {
    [user, attacker] = await ethers.getSigners();

    const MirkoToken = await ethers.getContractFactory("MirkoToken");
    mirkoToken = await MirkoToken.deploy(50000);
    await mirkoToken.deployed();

    const TokenLocker = await ethers.getContractFactory("TokenLocker");
    tokenLocker = await TokenLocker.deploy();
    await tokenLocker.deployed();
  });

  it("should correctly lock the tokens", async function () {
    await mirkoToken.approve(tokenLocker.address, 20000);

    await tokenLocker.lockTokens(mirkoToken.address, 20000, 5);

    const blockNumber = await ethers.provider.getBlockNumber();
    const block = await ethers.provider.getBlock(blockNumber);
    const timestamp = block.timestamp;

    const locks = await tokenLocker.getAllActiveLocks();
    const lock = locks[0];

    expect(await mirkoToken.balanceOf(tokenLocker.address)).to.equal(20000);

    expect(lock.lockId).to.equal(0);
    expect(lock.tokenContract).to.equal(mirkoToken.address);
    expect(lock.locker).to.equal(user.address);
    expect(lock.amount).to.equal(20000);
    expect(lock.unlockTime).to.equal(timestamp + 5 * 3600);
    expect(lock.withdrawn).to.equal(false);
  });

  it("should let owner unlock his tokens after unlock time", async function () {
    await mirkoToken.approve(tokenLocker.address, 20000);

    await tokenLocker.lockTokens(mirkoToken.address, 20000, 5);

    const locks = await tokenLocker.getAllActiveLocks();
    const unlockTime = locks[0].unlockTime.toNumber();

    await ethers.provider.send("evm_mine", [unlockTime + 1]);

    await tokenLocker.withdrawTokens(mirkoToken.address, 0);

    expect(await mirkoToken.balanceOf(tokenLocker.address)).to.equal(0);
    expect(await mirkoToken.balanceOf(user.address)).to.equal(50000);
  });

  it("should not let attacker to unlock tokens after unlock time", async function () {
    await mirkoToken.approve(tokenLocker.address, 20000);

    await tokenLocker.lockTokens(mirkoToken.address, 20000, 5);

    const locks = await tokenLocker.getAllActiveLocks();
    const unlockTime = locks[0].unlockTime.toNumber();

    await ethers.provider.send("evm_mine", [unlockTime - 100]);

    await expect(
      tokenLocker.connect(attacker).withdrawTokens(mirkoToken.address, 0)
    ).to.be.revertedWith("you are not owner of tokens!");
  });

  it("should not let owner unlock his tokens before unlock time", async function () {
    await mirkoToken.approve(tokenLocker.address, 20000);

    await tokenLocker.lockTokens(mirkoToken.address, 20000, 5);

    const locks = await tokenLocker.getAllActiveLocks();
    const unlockTime = locks[0].unlockTime.toNumber();

    await ethers.provider.send("evm_mine", [unlockTime - 100]);

    await expect(
      tokenLocker.withdrawTokens(mirkoToken.address, 0)
    ).to.be.revertedWith("you must wait for unlock!");
  });

  it("should not let owner unlock his tokens twice", async function () {
    await mirkoToken.approve(tokenLocker.address, 20000);

    await tokenLocker.lockTokens(mirkoToken.address, 20000, 5);

    const locks = await tokenLocker.getAllActiveLocks();
    const unlockTime = locks[0].unlockTime.toNumber();

    await ethers.provider.send("evm_mine", [unlockTime + 1]);

    await tokenLocker.withdrawTokens(mirkoToken.address, 0);

    await expect(
      tokenLocker.withdrawTokens(mirkoToken.address, 0)
    ).to.be.revertedWith("you already withdrawn your tokens!");
  });
});

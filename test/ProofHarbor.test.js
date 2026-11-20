const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const DAY = 86400;
const ZERO_BYTES32 = "0x" + "00".repeat(32);

describe("ProofHarbor", function () {
  let registry, harbor;
  let alice, bob, carol; // alice & bob hold an Agent ID; carol does not

  beforeEach(async function () {
    [, alice, bob, carol] = await ethers.getSigners();

    const Mock = await ethers.getContractFactory("MockAgentID");
    registry = await Mock.deploy();
    await registry.mint(alice.address);
    await registry.mint(bob.address);

    const Harbor = await ethers.getContractFactory("ProofHarbor");
    harbor = await Harbor.deploy(await registry.getAddress());
  });

  async function currentDay() {
    return Number(await harbor.currentDay());
  }

  describe("holder gate", function () {
    it("rejects non-holders on all three write functions", async function () {
      await expect(harbor.connect(carol).checkIn()).to.be.revertedWith(
        "ProofHarbor: not an Agent ID holder"
      );
      await expect(
        harbor.connect(carol).submitProof(ethers.keccak256("0x01"), "work")
      ).to.be.revertedWith("ProofHarbor: not an Agent ID holder");
      await expect(harbor.connect(carol).signGuestbook("hello")).to.be.revertedWith(
        "ProofHarbor: not an Agent ID holder"
      );
    });

    it("reverts deployment with a zero registry address", async function () {
      const Harbor = await ethers.getContractFactory("ProofHarbor");
      await expect(Harbor.deploy(ethers.ZeroAddress)).to.be.revertedWith(
        "ProofHarbor: registry is zero address"
      );
    });
  });

  describe("checkIn", function () {
    it("lets a holder check in and records stats", async function () {
      const today = await currentDay();
      await expect(harbor.connect(alice).checkIn())
        .to.emit(harbor, "CheckedIn")
        .withArgs(alice.address, today, 1);

      const [streak, total, proofCount, lastDay] = await harbor.holderStats(alice.address);
      expect(streak).to.equal(1);
      expect(total).to.equal(1);
      expect(proofCount).to.equal(1);
      expect(lastDay).to.equal(today);
    });

    it("reverts on a second check-in the same day", async function () {
      await harbor.connect(alice).checkIn();
      await expect(harbor.connect(alice).checkIn()).to.be.revertedWith(
        "ProofHarbor: already checked in today"
      );
    });

    it("increments the streak on the next day", async function () {
      await harbor.connect(alice).checkIn();
      await time.increase(DAY);
      const today = await currentDay();
      await expect(harbor.connect(alice).checkIn())
        .to.emit(harbor, "CheckedIn")
        .withArgs(alice.address, today, 2);

      const [streak, total] = await harbor.holderStats(alice.address);
      expect(streak).to.equal(2);
      expect(total).to.equal(2);
    });

    it("resets the streak to 1 after a missed day", async function () {
      await harbor.connect(alice).checkIn();
      await time.increase(DAY);
      await harbor.connect(alice).checkIn(); // streak 2
      await time.increase(2 * DAY); // skip a full day
      await harbor.connect(alice).checkIn();

      const [streak, total] = await harbor.holderStats(alice.address);
      expect(streak).to.equal(1);
      expect(total).to.equal(3);
    });

    it("auto-creates exactly one ACTIVITY proof per check-in", async function () {
      const today = await currentDay();
      await expect(harbor.connect(alice).checkIn())
        .to.emit(harbor, "ProofRecorded")
        .withArgs(alice.address, 0, 0, ZERO_BYTES32, today);

      const proofs = await harbor.proofsOf(alice.address);
      expect(proofs.length).to.equal(1);
      expect(proofs[0].kind).to.equal(0); // ACTIVITY
      expect(proofs[0].refHash).to.equal(ZERO_BYTES32);
      expect(proofs[0].note).to.equal("");
      expect(proofs[0].day).to.equal(today);
      expect(proofs[0].streak).to.equal(1);
      expect(await harbor.proofCountTotal()).to.equal(1);
    });
  });

  describe("submitProof", function () {
    it("stores the given hash and note and increments counts", async function () {
      const ref = ethers.keccak256(ethers.toUtf8Bytes("external-tx"));
      await harbor.connect(alice).checkIn(); // 1 activity proof first

      await expect(harbor.connect(alice).submitProof(ref, "shipped the thing"))
        .to.emit(harbor, "ProofRecorded")
        .withArgs(alice.address, 1, 1, ref, await currentDay());

      const proofs = await harbor.proofsOf(alice.address);
      expect(proofs.length).to.equal(2);
      expect(proofs[1].kind).to.equal(1); // WORK
      expect(proofs[1].refHash).to.equal(ref);
      expect(proofs[1].note).to.equal("shipped the thing");

      const [, , proofCount] = await harbor.holderStats(alice.address);
      expect(proofCount).to.equal(2);
      expect(await harbor.proofCountTotal()).to.equal(2);
      expect(await harbor.proofCountOf(alice.address)).to.equal(2);
    });

    it("rejects notes longer than 140 bytes", async function () {
      const ref = ethers.keccak256("0x02");
      await expect(
        harbor.connect(alice).submitProof(ref, "x".repeat(141))
      ).to.be.revertedWith("ProofHarbor: note too long");
      await harbor.connect(alice).submitProof(ref, "x".repeat(140)); // exactly 140 is fine
      expect(await harbor.proofCountOf(alice.address)).to.equal(1);
    });

    it("supports the paged proofs getter", async function () {
      await harbor.connect(alice).checkIn();
      await harbor.connect(alice).submitProof(ethers.keccak256("0x03"), "a");
      await harbor.connect(alice).submitProof(ethers.keccak256("0x04"), "b");

      const page = await harbor["proofsOf(address,uint256,uint256)"](alice.address, 1, 1);
      expect(page.length).to.equal(1);
      expect(page[0].note).to.equal("a");

      const empty = await harbor["proofsOf(address,uint256,uint256)"](alice.address, 99, 10);
      expect(empty.length).to.equal(0);
    });
  });

  describe("guestbook", function () {
    it("signs and then updates the holder's entry", async function () {
      await expect(harbor.connect(alice).signGuestbook("first visit"))
        .to.emit(harbor, "GuestbookSigned")
        .withArgs(alice.address);

      let [message] = await harbor.guestbookOf(alice.address);
      expect(message).to.equal("first visit");

      await harbor.connect(alice).signGuestbook("updated note");
      [message] = await harbor.guestbookOf(alice.address);
      expect(message).to.equal("updated note");
    });

    it("rejects messages longer than 280 bytes", async function () {
      await expect(harbor.connect(alice).signGuestbook("y".repeat(281))).to.be.revertedWith(
        "ProofHarbor: message too long"
      );
    });
  });

  describe("unique holders registry", function () {
    it("counts each holder once across multiple different actions", async function () {
      expect(await harbor.totalHolders()).to.equal(0);

      await harbor.connect(alice).checkIn();
      await harbor.connect(alice).submitProof(ethers.keccak256("0x05"), "x");
      await harbor.connect(alice).signGuestbook("hi");
      expect(await harbor.totalHolders()).to.equal(1);
      expect(await harbor.isKnownHolder(alice.address)).to.equal(true);

      await harbor.connect(bob).signGuestbook("bob was here");
      expect(await harbor.totalHolders()).to.equal(2);

      const page = await harbor.holdersPage(0, 10);
      expect(page).to.deep.equal([alice.address, bob.address]);

      const page2 = await harbor.holdersPage(1, 1);
      expect(page2).to.deep.equal([bob.address]);
    });
  });
});

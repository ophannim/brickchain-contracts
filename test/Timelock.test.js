const { expectRevert, time } = require("@openzeppelin/test-helpers");
const ethers = require("ethers");
const BrickToken = artifacts.require("BrickToken");
const Builder = artifacts.require("Builder");
const TestToken = artifacts.require("TestToken");
const Timelock = artifacts.require("Timelock");

function encodeParameters(types, values) {
  const abi = new ethers.utils.AbiCoder();
  return abi.encode(types, values);
}

contract(
  "Timelock",
  ([alice, bob, carol, dev, product, feeAddress, minter]) => {
    beforeEach(async () => {
      this.brick = await BrickToken.new({ from: alice });
      this.timelock = await Timelock.new(bob, "28800", { from: alice }); //8hours
    });

    it("should not allow non-owner to do operation", async () => {
      await this.brick.transferOwnership(this.timelock.address, {
        from: alice,
      });
      await expectRevert(
        this.brick.transferOwnership(carol, { from: alice }),
        "Ownable: caller is not the owner"
      );
      await expectRevert(
        this.brick.transferOwnership(carol, { from: bob }),
        "Ownable: caller is not the owner"
      );
      await expectRevert(
        this.timelock.queueTransaction(
          this.brick.address,
          "0",
          "transferOwnership(address)",
          encodeParameters(["address"], [carol]),
          (await time.latest()).add(time.duration.hours(6)),
          { from: alice }
        ),
        "Timelock::queueTransaction: Call must come from admin."
      );
    });

    it("should do the timelock thing", async () => {
      await this.brick.transferOwnership(this.timelock.address, {
        from: alice,
      });
      const eta = (await time.latest()).add(time.duration.hours(9));
      await this.timelock.queueTransaction(
        this.brick.address,
        "0",
        "transferOwnership(address)",
        encodeParameters(["address"], [carol]),
        eta,
        { from: bob }
      );
      await time.increase(time.duration.hours(1));
      await expectRevert(
        this.timelock.executeTransaction(
          this.brick.address,
          "0",
          "transferOwnership(address)",
          encodeParameters(["address"], [carol]),
          eta,
          { from: bob }
        ),
        "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
      );
      await time.increase(time.duration.hours(8));
      await this.timelock.executeTransaction(
        this.brick.address,
        "0",
        "transferOwnership(address)",
        encodeParameters(["address"], [carol]),
        eta,
        { from: bob }
      );
      assert.equal((await this.brick.owner()).valueOf(), carol);
    });

    it("should also work with Builder", async () => {
      this.lp1 = await TestToken.new("LPToken", "LP", "10000000000", {
        from: minter,
      });
      this.lp2 = await TestToken.new("LPToken", "LP", "10000000000", {
        from: minter,
      });
      this.builder = await Builder.new(
        this.brick.address,
        dev,
        product,
        feeAddress,
        "1000",
        "0",
        {
          from: alice,
        }
      );

      await this.brick.transferOwnership(this.builder.address, { from: alice });
      await this.builder.add("100", this.lp1.address, 0, true, { from: alice });
      await this.builder.transferOwnership(this.timelock.address, {
        from: alice,
      });
      await expectRevert(
        this.builder.add("100", this.lp1.address, 0, true, { from: alice }),
        "revert Ownable: caller is not the owner"
      );

      const eta = (await time.latest()).add(time.duration.hours(9));
      await this.timelock.queueTransaction(
        this.builder.address,
        "0",
        "transferOwnership(address)",
        encodeParameters(["address"], [minter]),
        eta,
        { from: bob }
      );
      
      await time.increase(time.duration.hours(9));
      await this.timelock.executeTransaction(
        this.builder.address,
        "0",
        "transferOwnership(address)",
        encodeParameters(["address"], [minter]),
        eta,
        { from: bob }
      );
      await expectRevert(
        this.builder.add("100", this.lp2.address, 0, true, { from: alice }),
        "revert Ownable: caller is not the owner"
      );
      await this.builder.add("100", this.lp2.address, 0, true, {
        from: minter,
      });
    });
    
  }
);

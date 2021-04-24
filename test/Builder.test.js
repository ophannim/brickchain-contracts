const { expectRevert, time } = require("@openzeppelin/test-helpers");
const BrickToken = artifacts.require("BrickToken");
const Builder = artifacts.require("Builder");
const TestToken = artifacts.require("TestToken");

contract(
  "Builder",
  ([alice, bob, charly, dev, product, feeAddress, minter]) => {
    beforeEach(async () => {
      this.brick = await BrickToken.new({ from: minter });

      this.lp1 = await TestToken.new("LPToken", "LP1", "1000000", {
        from: minter,
      });
      this.lp2 = await TestToken.new("LPToken", "LP2", "1000000", {
        from: minter,
      });
      this.lp3 = await TestToken.new("LPToken", "LP3", "1000000", {
        from: minter,
      });

      this.builder = await Builder.new(
        this.brick.address, // token address
        dev, // dev address
        product, // product address
        feeAddress, // fee address to rebuy brick tokens
        "1000", // amount of brick per block
        "100", // start block
        {
          from: minter,
        }
      );
      await this.brick.transferOwnership(this.builder.address, {
        from: minter,
      });

      await this.lp1.transfer(bob, "2000", { from: minter });
      await this.lp2.transfer(bob, "2000", { from: minter });
      await this.lp3.transfer(bob, "2000", { from: minter });

      await this.lp1.transfer(alice, "2000", { from: minter });
      await this.lp2.transfer(alice, "2000", { from: minter });
      await this.lp3.transfer(alice, "2000", { from: minter });
    });

    it("success poolLength operation", async () => {
      this.lp4 = await TestToken.new("LPToken", "LP1", "1000000", {
        from: minter,
      });
      this.lp5 = await TestToken.new("LPToken", "LP2", "1000000", {
        from: minter,
      });
      this.lp6 = await TestToken.new("LPToken", "LP3", "1000000", {
        from: minter,
      });
      this.lp7 = await TestToken.new("LPToken", "LP1", "1000000", {
        from: minter,
      });
      this.lp8 = await TestToken.new("LPToken", "LP2", "1000000", {
        from: minter,
      });
      this.lp9 = await TestToken.new("LPToken", "LP3", "1000000", {
        from: minter,
      });
      await this.builder.add("2000", this.lp1.address, 0, true, {
        from: minter,
      });
      await this.builder.add("1000", this.lp2.address, 0, true, {
        from: minter,
      });
      await this.builder.add("500", this.lp3.address, 0, true, {
        from: minter,
      });
      await this.builder.add("500", this.lp4.address, 0, true, {
        from: minter,
      });
      await this.builder.add("500", this.lp5.address, 0, true, {
        from: minter,
      });
      await this.builder.add("500", this.lp6.address, 0, true, {
        from: minter,
      });
      await this.builder.add("500", this.lp7.address, 0, true, {
        from: minter,
      });
      await this.builder.add("100", this.lp8.address, 0, true, {
        from: minter,
      });
      await this.builder.add("100", this.lp9.address, 0, true, {
        from: minter,
      });
      await expectRevert(
        this.builder.add("100", this.lp9.address, 0, true, {
          from: minter,
        }),
        "add: this lp already exist"
      );
      assert.equal((await this.builder.poolLength()).toString(), "9");
    });

    it("should not mint before the start date", async () => {
      // 1000 per block pouring rate starting at block 100
      await this.builder.add("100", this.lp1.address, 0, true, {
        from: minter,
      });
      await this.lp1.approve(this.builder.address, "1000", { from: bob });
      await this.builder.deposit(0, "100", { from: bob });
      await time.advanceBlockTo("89");
      await this.builder.deposit(0, "0", { from: bob }); // block 90
      assert.equal((await this.brick.balanceOf(bob)).toString(), "0");
    });

    it("deposit/withdraw operation", async () => {
      const pid = 0; // 1000 bricks to distribute per block
      await this.builder.add("1000", this.lp1.address, 0, true, {
        from: minter,
      });
      await this.builder.add("1000", this.lp2.address, 0, true, {
        from: minter,
      });
      await this.builder.add("1000", this.lp3.address, 0, true, {
        from: minter,
      });

      await this.lp1.approve(this.builder.address, "100", { from: alice });

      await this.builder.deposit(pid, "20", { from: alice });
      await this.builder.deposit(pid, "0", { from: alice });
      await this.builder.deposit(pid, "40", { from: alice });
      await this.builder.deposit(pid, "0", { from: alice });

      assert.equal((await this.lp1.balanceOf(alice)).toString(), "1940");

      assert.equal((await this.brick.balanceOf(dev)).toString(), "60");
      assert.equal((await this.brick.balanceOf(product)).toString(), "60");

      await this.builder.withdraw(pid, "10", { from: alice });
      assert.equal((await this.lp1.balanceOf(alice)).toString(), "1950");

      assert.equal((await this.brick.balanceOf(alice)).toString(), "1320"); // 999
      assert.equal((await this.brick.balanceOf(dev)).toString(), "80");
      assert.equal((await this.brick.balanceOf(product)).toString(), "80");

      await this.lp1.approve(this.builder.address, "100", { from: bob });
      assert.equal((await this.lp1.balanceOf(bob)).toString(), "2000");
      await this.builder.deposit(pid, "50", { from: bob });
      assert.equal((await this.lp1.balanceOf(bob)).toString(), "1950");
      await this.builder.deposit(pid, "0", { from: bob });
      assert.equal((await this.brick.balanceOf(bob)).toString(), "165"); // 125
      await this.builder.emergencyWithdraw(pid, { from: bob });
      assert.equal((await this.lp1.balanceOf(bob)).toString(), "2000");
    });

    it("should allow emergency withdraw", async () => {
      await this.builder.add("100", this.lp1.address, 0, true, {
        from: minter,
      });
      await this.lp1.approve(this.builder.address, "1000", { from: bob });

      const pid = 0;
      await this.builder.deposit(pid, "100", { from: bob });
      assert.equal((await this.lp1.balanceOf(bob)).toString(), "1900");

      await this.builder.emergencyWithdraw(pid, { from: bob });
      assert.equal((await this.lp1.balanceOf(bob)).toString(), "2000");
    });

    it("should allow dev and only dev to update dev", async () => {
      assert.equal((await this.builder.devAddr()).toString(), dev);
      await expectRevert(
        this.builder.dev(bob, { from: bob }),
        "dev: invalid sender"
      );
      await this.builder.dev(bob, { from: dev });
      assert.equal((await this.builder.devAddr()).toString(), bob);
      await this.builder.dev(alice, { from: bob });
      assert.equal((await this.builder.devAddr()).toString(), alice);
    });

    it("should allow product and only product to update product", async () => {
      assert.equal((await this.builder.productAddr()).toString(), product);
      await expectRevert(
        this.builder.product(charly, { from: charly }),
        "product: invalid sender"
      );
      await this.builder.product(charly, { from: product });
      assert.equal((await this.builder.productAddr()).toString(), charly);
      await this.builder.product(alice, { from: charly });
      assert.equal((await this.builder.productAddr()).toString(), alice);
    });
  }
);

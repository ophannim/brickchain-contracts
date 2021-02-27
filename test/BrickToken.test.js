const { assert } = require("chai");

const BrickToken = artifacts.require("BrickToken");

contract("BrickToken", ([alice, minter]) => {
  beforeEach(async () => {
    this.brick = await BrickToken.new({ from: minter });
  });

  it("mint", async () => {
    await this.brick.mint(alice, 1000, { from: minter });
    assert.equal((await this.brick.balanceOf(alice)).toString(), "1000");
  });
});

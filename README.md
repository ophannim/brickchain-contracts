# Brickchain Farming 🥞

https://brickchain.finance

## Deployed Contracts

### BSCMAINNET

- Builder - 0x7854Fb0EdD06a880EC8009c62b1Aa38E26F9988D
- BrickToken - 0xc4daa5a9f2b832ed0f9bc579662883cd53ea9d61
- Timelock - 0x7289Cb0dAd995aA56ec1EC03E895db621F76FCaE
- MultiCall - 0xE1dDc30f691CA671518090931e3bFC1184BFa4Aa

#### Audit (Certik)

BTE01: Delegation Not Moved Along With transfer and transferFrom

- 9eeee373c89c033531efd98f57adf9f0e55656b8

BTE03: Privileged Ownerships on BrickToken

- The BrickToken was transferred in favor to Builder (MasterChef)
- The Builder (MasterChef) was transferred in favor to Timelock.
- The Timelock is use with multisign gnosis wallet

BUI01: add() Function Not Restricted

- e2cd259a4422a0a553e6bd2750af32f6044517f7

BUI02: Missing Zero Address Validation

- TODO

BUI03: Proper Usage of Public and External

- TODO



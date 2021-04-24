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

- 6c6e65238fc34fc3df6707b457e4a561c654ce00

BTE03: Privileged Ownerships on BrickToken
- dbd2344148dcc5f2643fcecbeb63e63f2d2f6f3c
- The BrickToken was transferred in favor to Builder (MasterChef)
- The Builder (MasterChef) was transferred in favor to Timelock.
- The Timelock is use with multisign gnosis wallet

BUI01: add() Function Not Restricted

- 8b44bf663d459c2eb82cbb9b65656c201e71d7f7

BUI02: Missing Zero Address Validation

- f8f829cc1f208b039a8b37be66b4eda4c99b8ec9

BUI03: Proper Usage of Public and External

- 415f75735a25ed55c850c9c6e2e29be73f61c880

BUI04: Missing Emit Event

- 1f01b8619b17688b87bc3bb45d668dfbd5b349a0

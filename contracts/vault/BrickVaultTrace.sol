// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BrickVaultTrace is BrickVault {
    /**
     * The time for the last desposit per user,
     * this information will be use for airdrops, lotteries, etc
     * sender address => time to deposit
     */
    mapping(address => uint256) tracing;

    /**
     * @dev Sets the value of {token} to the token that the vault will
     * hold as underlying value. It initializes the vault's own 'brickstation' token.
     * This token is minted when someone does a deposit. It is burned in order
     * to withdraw the corresponding portion of the underlying assets.
     * @param _token the token to maximize.
     * @param _strategy the address of the strategy.
     * @param _name the name of the vault token.
     * @param _symbol the symbol of the vault token.
     * @param _approvalDelay the delay before a new strat can be approved.
     */
    constructor(
        address _token,
        address _strategy,
        string memory _name,
        string memory _symbol,
        uint256 _approvalDelay
    ) public BrickVault(_token, _strategy, _name, _symbol, _approvalDelay) {}

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function deposit(uint256 _amount) public {
        tracing[msg.sender] = now;
        super.deposit(_amount);
    }

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of IOU
     * tokens are burned in the process.
     */
    function withdraw(uint256 _shares) public override {
        delete tracing[msg.sender];
        super.withdraw(_shares);
    }
}

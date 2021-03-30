// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./BrickToken.sol";

contract BuilderWrapper {
    Builder public builder;
    IERC20 public brickToken;
    mapping (uint256 => address) lpPools;

    constructor(Builder _builder) public {
        builder = _builder;
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return 
    }

    /// @notice View function to see pending Bricks on frontend.
    function pendingBrick(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        return builder.pendingBrick(_pid, user);
    }

    /// @notice Deposit LP tokens to BuilderWrapper for Brick allocation then move this into Builder.
    function deposit(uint256 _pid, uint256 _amount) public {
        ERC20 token = lpPools[_pid];
        uint256 _pool = token.balanceOf(address(this));
        require(token != address(0), 'invalid request');
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); 
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(token.totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    /// @notice Withdraw LP tokens from Builder.
    function withdraw(uint256 _pid, uint256 _amount) public {
        
    }

}

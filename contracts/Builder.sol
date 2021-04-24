// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./BrickToken.sol";

// Builder is the better builder of Brick.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Brick is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

contract Builder is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Bricks
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBrickPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBrickPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Bricks to distribute per block.
        uint256 lastRewardBlock; // Last block number that Bricks distribution occurs.
        uint256 accBrickPerShare; // Accumulated Bricks per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
    }

    // The Brick TOKEN!
    BrickToken public brick;
    // Dev address. (4%)
    address public devAddr;
    // Product address. (4%)
    address public productAddr;
    // Brick tokens created per block.
    uint256 public brickPerBlock;
    // Bonus muliplier for early brick makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee will be used to buyback Brick when the staking is from an external pool
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Brick mining starts.
    uint256 public startBlock;
    // The Existing pools.
    mapping(address => bool) public existingPools;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        BrickToken _brick,
        address _devAddr,
        address _productAddr,
        address _feeAddress,
        uint256 _brickPerBlock,
        uint256 _startBlock
    ) public {
        brick = _brick;
        devAddr = _devAddr;
        productAddr = _productAddr;
        feeAddress = _feeAddress;
        brickPerBlock = _brickPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        address lpTokenAddr = address(_lpToken);
        require(!existingPools[lpTokenAddr], "add: this lp already exist");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        existingPools[lpTokenAddr] = true;

        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accBrickPerShare: 0,
                depositFeeBP: _depositFeeBP
            })
        );
    }

    /// @notice Update the given pool's Brick allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "set: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    /// @notice View function to see pending Bricks on frontend.
    function pendingBrick(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBrickPerShare = pool.accBrickPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 brickReward =
                multiplier.mul(brickPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accBrickPerShare = accBrickPerShare.add(
                brickReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accBrickPerShare).div(1e12).sub(user.rewardDebt);
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 brickReward =
            multiplier.mul(brickPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

        uint256 teamReward = brickReward.div(8);
        brick.mint(devAddr, teamReward.div(2));
        brick.mint(productAddr, teamReward.div(2));
        brick.mint(address(this), brickReward);

        pool.accBrickPerShare = pool.accBrickPerShare.add(
            brickReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    /// @notice Deposit LP tokens to Builder for Brick allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accBrickPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeBrickTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accBrickPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw LP tokens from Builder.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accBrickPerShare).div(1e12).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            safeBrickTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBrickPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice Safe brick transfer function, just in case if rounding error causes pool to not have enough Bricks.
    function safeBrickTransfer(address _to, uint256 _amount) internal {
        uint256 brickBal = brick.balanceOf(address(this));
        if (_amount > brickBal) {
            brick.transfer(_to, brickBal);
        } else {
            brick.transfer(_to, _amount);
        }
    }

    /// @notice Update dev address by the previous dev.
    function dev(address _devAddr) public {
        require(msg.sender == devAddr, "dev: invalid sender");
        devAddr = _devAddr;
    }

    /// @notice Update dev address by the previous pm.
    function product(address _productAddr) public {
        require(msg.sender == productAddr, "product: invalid sender");
        productAddr = _productAddr;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    /// @notice transparent and simple way to alter the emission.
    function updateEmissionRate(uint256 _brickPerBlock) public onlyOwner {
        massUpdatePools();
        brickPerBlock = _brickPerBlock;
    }
}

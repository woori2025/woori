// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/// @title SafeMath
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b; require(c >= a, "SafeMath: add overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath: sub underflow"); c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
        c = a * b; require(c / a == b, "SafeMath: mul overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b != 0, "SafeMath: div by zero"); c = a / b;
        return c;
    }
}

/// @title ERC-20
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256);
    event Approval(address indexed owner, address indexed spender, uint256);
}

/// @notice ERC-20
contract Woori is IERC20 {
    using SafeMath for uint256;

    uint256 private deploymentBlock = 5448823;


    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 private _totalSupply;
    address public owner;

    address private _pendingOwner;
    /// @dev
    uint256 private _ownershipTransferDeadline;
    /// @dev 1day
    uint256 private constant OWNERSHIP_TRANSFER_EXPIRE = 2 days;

    /// @dev
    bool private _paused;

    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @dev
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /// @dev
    event Paused(address account);

    /// @dev
    event Unpaused(address account);

    /**
     * @dev Initializes the custom token.
     * @param _name         The name of the token.
     * @param _symbol       The symbol (ticker) of the token.
     * @param _decimals     The number of decimal places the token uses.
     * @param _initialSupply The initial supply of tokens (in the smallest unit, e.g., wei).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8   _decimals,
        uint256 _initialSupply,
        address initialAddress
    ) {
        name         = _name;
        symbol       = _symbol;
        decimals     = _decimals;
        owner        = initialAddress;
        _totalSupply = _initialSupply.mul(10 ** uint256(_decimals));
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    /// @notice modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }



mapping(address => bool) private _blacklist;
event Blacklisted(address indexed account);
event Unblacklisted(address indexed account);


modifier notFrozen(address account) {
require(!_blacklist[account], "Blacklisted");
_;
}


function freezeAccount(address account) external onlyOwner {
require(!_blacklist[account], "Already blacklisted");
_blacklist[account] = true;
emit Blacklisted(account);
}


function unfreezeAccount(address account) external onlyOwner {
require(_blacklist[account], "Not blacklisted");
_blacklist[account] = false;
emit Unblacklisted(account);
}


function isFrozenAccount(address account) external view returns (bool) {
return _blacklist[account];
}

function _beforeTokenTransfer(address from, address to) internal view {
if (from != address(0)) require(!_blacklist[from], "Sender blacklisted");
if (to   != address(0)) require(!_blacklist[to],   "Recipient blacklisted");
}


modifier whenNotPaused() {
require(!_paused, "Contract is paused");
_;
}


modifier whenPaused() {
require(_paused, "Contract is not paused");
_;
}

function totalSupply() external view override returns (uint256) {
return _totalSupply;
}

function balanceOf(address who) external view override returns (uint256) {
return _balances[who];
}

function transfer(address to, uint256 value)
external
override
whenNotPaused
returns (bool) {

_beforeLockup(msg.sender, value);
_beforeTokenTransfer(msg.sender, to);
require(to != address(0),                "Invalid recipient");
require(_balances[msg.sender] >= value, "Insufficient balance");
_balances[msg.sender] = _balances[msg.sender].sub(value);
_balances[to]         = _balances[to].add(value);
emit Transfer(msg.sender, to, value);
return true;
}

function approve(address spender, uint256 value) external override returns (bool) {
require(spender != address(0), "Invalid spender");
_allowances[msg.sender][spender] = value;
emit Approval(msg.sender, spender, value);
return true;
}

function transferFrom(address from, address to, uint256 value)
external
override
whenNotPaused
returns
(bool) {

_beforeLockup(from, value);
_beforeTokenTransfer(from, to);
require(from != address(0) && to != address(0), "Invalid address");
require(_balances[from] >= value,              "Insufficient balance");
require(_allowances[from][msg.sender] >= value, "Allowance exceeded");
_balances[from]              = _balances[from].sub(value);
_balances[to]                = _balances[to].add(value);
_allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
emit Transfer(from, to, value);
return true;
}

function allowance(address owner_, address spender) external view override returns (uint256) {
return _allowances[owner_][spender];
}


/// @notice Pauses the contract.
function pause() external onlyOwner {
require(!_paused, "Already paused");
_paused = true;
emit Paused(msg.sender);
}

/// @notice Unpauses the contract.
function unpause() external onlyOwner {
require(_paused, "Not paused");
_paused = false;
emit Unpaused(msg.sender);
}

/// @notice Returns the current paused state of the contract.
/// @return “True indicates that the contract is paused.”
function paused() external view returns (bool) {
return _paused;
}


function transferOwnership(address newOwner) public onlyOwner {
require(newOwner != address(0), "New owner is zero address");

_pendingOwner = newOwner;
_ownershipTransferDeadline = block.timestamp + OWNERSHIP_TRANSFER_EXPIRE;
emit OwnershipTransferStarted(owner, newOwner);
}


function acceptOwnership() public {
require(msg.sender == _pendingOwner, "Caller is not pending owner");
require(block.timestamp <= _ownershipTransferDeadline, "Ownership request expired");

emit OwnershipTransferred(owner, _pendingOwner);
owner = _pendingOwner;
_pendingOwner = address(0);
_ownershipTransferDeadline = 0;
}

/// @notice (renounce)
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);

_pendingOwner = address(0);
_ownershipTransferDeadline = 0;
}

function cancelPendingOwnership() public onlyOwner {
require(_pendingOwner != address(0), "No pending transfer");
require(block.timestamp > _ownershipTransferDeadline, "Not yet expired");

_pendingOwner = address(0);
_ownershipTransferDeadline = 0;
}



/// @dev
mapping(address => uint256) private _locked;

/// @dev
event Locked(address indexed account, uint256 amount);
event Unlocked(address indexed account, uint256 amount);

/// @notice account locked
/// @param account userAddress
/// @param amount lockupAmount
function lockup(address account, uint256 amount) external onlyOwner {
_locked[account] = _locked[account].add(amount);
emit Locked(account, amount);
}


/// @notice account unlock
/// @param account userAddress
/// @param amount unLockMount
function unlockup(address account, uint256 amount) external onlyOwner {

require(
_locked[account] >= amount,
"Unlock amount exceeds locked balance"
);


_locked[account] = _locked[account].sub(amount);
emit Unlocked(account, amount);
}

/// @notice account
/// @param account userAddress
/// @return
function lockedBalanceOf(address account) external view returns (uint256) {
    return _locked[account];
}

/// @dev
function _beforeLockup(address from, uint256 value) internal view {
require(
_balances[from].sub(value) >= _locked[from],
"Transfer exceeds unlocked balance"
);
}
/**
 * @notice burn
     * @dev
     */
    function burn(uint256 amount)
    external
    whenNotPaused
    notFrozen(msg.sender)
    returns (bool)
    {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply          = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }


}

pragma solidity ^0.8.13;
// SPDX-License-Identifier: UNLICENSED 

//USE IT AT YOUR OWN RISK. NOT COMPLETE NOR TESTED YET!!


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface SmartDefi{
    function  _totalSupply1() external returns(uint256);
    function  _totalSupply2() external returns(uint256);
    function  _totalSupply7() external returns(uint256);
    function  _totalSupply8() external returns(uint256);
}

contract LPprovider{
    uint256 private _unlock; 
    bool  private _rentrenceLock = true;
    mapping (address => bool) private _allowed;
    mapping (address => uint256) private _floor;
    //Change to feth for the ETH side
    address public fbnb = 0x87b1AccE6a1958E522233A737313C086551a5c76;
    //TODO change here
    address public token = 0xa3D522c151aD654b36BDFe7a69D0c405193A22F9;


    
    constructor() {
     _allowed[msg.sender] = true;
    }

    address private _activeTokenAddress;

    modifier onlyallowed() {
        require(_allowed[msg.sender], "allowed: caller is not the allowed list of allowed");
        _;
    }
    modifier lock(){
        require(_rentrenceLock,"Reentrency protection hit");
        _rentrenceLock = false;
        _;
        _rentrenceLock = true;
    }

    function  increaseLockByDay(uint256 amountOfDays) external onlyallowed{
        _unlock += amountOfDays * 86400;
    }

    function sync() external onlyallowed{
        _floor[fbnb] = IERC20(fbnb).balanceOf(address(this));
        _floor[token] = IERC20(token).balanceOf(address(this));
    }


    function getTokenBalance() internal returns(uint256) {
        return IERC20(token).balanceOf(address(this)) - SmartDefi(token)._totalSupply1();  
    }
        
    function getMainBalance() internal returns(uint256) {
        uint256 al = (SmartDefi(fbnb)._totalSupply2() +SmartDefi(fbnb)._totalSupply7() + SmartDefi(fbnb)._totalSupply8());
        return IERC20(fbnb).balanceOf(address(this)) - al;
    }

    function getBackAll() external lock onlyallowed{
        require(_unlock < block.timestamp,"Unlock time hasn't passed");
        uint256 amt = IERC20(fbnb).balanceOf(address(this));
        bool xfer = IERC20(fbnb).transfer(msg.sender, amt);
        require(xfer, "ERR_ERC20_FALSE");
        amt = IERC20(token).balanceOf(address(this));
        xfer = IERC20(token).transfer(msg.sender, amt);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function isallowed(address toCheck) external view returns(bool){
        return _allowed[toCheck];
    }
    function addallowed(address toAdd) external onlyallowed{
        _allowed[toAdd] = true;
    }
    function removeallowed(address toRemove) external onlyallowed{
        _allowed[toRemove] = false;
    }

    function reaminingTime() external view returns(uint256){
        if(block.timestamp > _unlock){
            return 0;
        }
        else{
            return _unlock - block.timestamp;
        }
    }

}

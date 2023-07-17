/**
 *Submitted for verification at BscScan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: stakeBG.sol


pragma solidity ^0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract StakingBT is ReentrancyGuard { 

    IERC20 public constant token = IERC20(0x3180FAC9A4906599B0b280faae0215006e693c90); //BT testtokens ЗАМЕНА
    address public immutable owner; 

    constructor (address _adr) {  
        owner = _adr;
        procentParametr = 1000;
        dayParametr = 24;
    }

    function balanceOfStakeContract () external view returns (uint ) { 
        return token.balanceOf( address(this));
    }

    function getPlayerTimeStamp() external view returns ( uint ) { 
         return playerValuesMap[msg.sender].playerTimeStamp - block.timestamp;
    }

    function getBlockTimeStamp() external view returns ( uint ) {
        return block.timestamp;
    }

    //Procent Parametr and Day Patametr 
    uint public procentParametr;
    uint public dayParametr;
    
    //Total Values
    uint public totatStaked; //сколько всего застейкано 
    uint public totalStakers; //сколько всего стейкеров

    //PlayerValues 
    struct PlayerValues { 
        uint playerStaked; // сколько застейкал игрок;
        uint playerTimeStamp; // Время когда игрок сможет снять;
        bool playerBool; // проверяем застейкано ли уже у игрока;
        uint playerPlan; // планстейкинга который выбрал игрок;
        uint playerRewards; //rewardaAfterCalculation
    }
    mapping ( address => PlayerValues) public playerValuesMap;

    //doStake
    function staked ( uint amount , uint plan ) external nonReentrant {
        require( amount > 0 , " zerro amount reject!"); // requaire amount 
        require( !playerValuesMap[msg.sender].playerBool , "alredy staked!"); // requaire bool 
        require(plan==7||plan==14||plan==30||plan==61||plan==90||plan==180||plan==365,"we don't have this plan");
        playerValuesMap[msg.sender].playerBool = true; // set bool 
        playerValuesMap[msg.sender].playerPlan = plan; // set plan 
        token.transferFrom(msg.sender, address(this), amount); // transfer token 
        playerValuesMap[msg.sender].playerStaked += amount; // set staked amount 
        uint calculateTimestampForPlayer =  calculateTimestamp(); // 
        playerValuesMap[msg.sender].playerTimeStamp = block.timestamp + calculateTimestampForPlayer;
        playerValuesMap[msg.sender].playerRewards=calculateRewards();
        totatStaked += amount;
        totalStakers++;
    }

    //doWithdraw
     function withdraw () external nonReentrant { 
        require( playerValuesMap[msg.sender].playerBool , "not staked!");
        require( playerValuesMap[msg.sender].playerTimeStamp < block.timestamp , "planPeriod are not finished");
        playerValuesMap[msg.sender].playerBool = false;
        token.transfer(msg.sender, playerValuesMap[msg.sender].playerRewards);
        totatStaked -=  playerValuesMap[msg.sender].playerStaked;
        totalStakers--;
        playerValuesMap[msg.sender].playerStaked =  0;
        playerValuesMap[msg.sender].playerRewards = 0;
    }

    //CalculateReward
    function calculateRewards() internal view returns ( uint rewards ) { 
        if ( playerValuesMap[msg.sender].playerPlan == 7 ) {
            rewards = playerValuesMap[msg.sender].playerStaked * 1010 / procentParametr;
            return rewards; 
        }  else if ( playerValuesMap[msg.sender].playerPlan == 14 ) { 
            rewards = playerValuesMap[msg.sender].playerStaked * 1027 / procentParametr;
            return rewards;  
        }  else if ( playerValuesMap[msg.sender].playerPlan == 30 ) { 
            rewards = playerValuesMap[msg.sender].playerStaked * 1070 / procentParametr;
            return rewards;  
        }   else if ( playerValuesMap[msg.sender].playerPlan == 61 ) { 
            rewards = playerValuesMap[msg.sender].playerStaked * 1165 / procentParametr;
            return rewards;  
        }   else if ( playerValuesMap[msg.sender].playerPlan == 90 ) { 
            rewards = playerValuesMap[msg.sender].playerStaked * 1280 / procentParametr;
            return rewards;  
        }   else if ( playerValuesMap[msg.sender].playerPlan == 180 ) { 
            rewards = playerValuesMap[msg.sender].playerStaked * 1640 / procentParametr;
            return rewards;  
        }   else if ( playerValuesMap[msg.sender].playerPlan == 365 ) { 
            rewards = playerValuesMap[msg.sender].playerStaked * 2450 / procentParametr;
            return rewards;  
        }   else revert("errore calculation 1");
    }

    //CalculateTimeStamp
    function calculateTimestamp() internal view returns ( uint lockedTime) { 
         if ( playerValuesMap[msg.sender].playerPlan == 7 ) {
            lockedTime = 7 * dayParametr * 60 * 60;
            return lockedTime; 
        } else if ( playerValuesMap[msg.sender].playerPlan == 14 ) { 
            lockedTime = 14 * dayParametr * 60 * 60;
            return lockedTime;   
        }  else if ( playerValuesMap[msg.sender].playerPlan == 30 ) { 
            lockedTime = 30 * dayParametr * 60 * 60;
            return lockedTime;   
        } else if ( playerValuesMap[msg.sender].playerPlan == 61 ) { 
            lockedTime = 61 * dayParametr * 60 * 60;
            return lockedTime;   
        } else if ( playerValuesMap[msg.sender].playerPlan == 90 ) { 
            lockedTime = 90 * dayParametr * 60 * 60;
            return lockedTime;   
        } else if ( playerValuesMap[msg.sender].playerPlan == 180 ) { 
            lockedTime = 180 * dayParametr * 60 * 60;
            return lockedTime;   
        } else if ( playerValuesMap[msg.sender].playerPlan == 365 ) { 
            lockedTime = 365 * dayParametr * 60 * 60;
            return lockedTime;   
        } else revert("errore calculation 2");
    }

    //onlyOwnerFunctions
    function sender(address to, uint amount ) external { 
        require(msg.sender == owner , "ownerReject");
        token.transfer(to, amount);
    }

    function setProcentParametr ( uint amount ) external { 
        require(msg.sender == owner , "ownerReject");
        procentParametr = amount;
    }

    function setdayParametr ( uint amount ) external { 
        require(msg.sender == owner , "ownerReject");
        dayParametr = amount;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TokenLocker {
    using Counters for Counters.Counter;

    struct Lock {
        uint256 lockId;
        address tokenContract;
        address locker;
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    Counters.Counter private _lockedLocksNumber;
    Counters.Counter private _unlockedLocksNumber;
    Lock[] private _allLocks;

    event TokensLocked(
        uint256 lockId,
        address tokenContract,
        address locker,
        uint256 amount,
        uint256 unlockTime
    );

    event TokensUnlocked(
        uint256 lockId,
        address tokenContract,
        address locker,
        uint256 amount
    );

    function lockTokens(
        address tokenContract,
        uint256 amount,
        uint256 timeInHours
    ) public {
        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
        uint256 unlockTime = block.timestamp + timeInHours * 1 hours;
        uint256 currentLockId = _lockedLocksNumber.current();
        _allLocks.push(
            Lock(
                currentLockId,
                tokenContract,
                msg.sender,
                amount,
                unlockTime,
                false
            )
        );
        _lockedLocksNumber.increment();
        emit TokensLocked(
            currentLockId,
            tokenContract,
            msg.sender,
            amount,
            unlockTime
        );
    }

    function withdrawTokens(address tokenContract, uint256 lockId) public {
        Lock memory lock = _allLocks[lockId];
        require(lock.locker == msg.sender, "you are not owner of tokens!");
        require(lock.withdrawn == false, "you already withdrawn your tokens!");
        require(lock.unlockTime < block.timestamp, "you must wait for unlock!");
        _allLocks[lockId].withdrawn = true;
        _unlockedLocksNumber.increment();
        IERC20(tokenContract).transfer(msg.sender, lock.amount);
        emit TokensUnlocked(lockId, tokenContract, msg.sender, lock.amount);
    }

    /* --- Getters --- */

    function getAllActiveLocks() public view returns (Lock[] memory) {
        uint256 activeLocksNumber = _lockedLocksNumber.current() -
            _unlockedLocksNumber.current();
        Lock[] memory activeLocks = new Lock[](activeLocksNumber);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _lockedLocksNumber.current(); i++) {
            if (_allLocks[i].withdrawn == false) {
                activeLocks[currentIndex] = _allLocks[i];
                currentIndex++;
            }
        }
        return activeLocks;
    }

    function getMyActiveLocks() public view returns (Lock[] memory) {
        uint256 activeLocksCounter = 0;
        for (uint256 i = 0; i < _lockedLocksNumber.current(); i++) {
            if (
                _allLocks[i].withdrawn == false &&
                _allLocks[i].locker == msg.sender
            ) {
                activeLocksCounter++;
            }
        }
        Lock[] memory myActiveLocks = new Lock[](activeLocksCounter);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _lockedLocksNumber.current(); i++) {
            if (
                _allLocks[i].withdrawn == false &&
                _allLocks[i].locker == msg.sender
            ) {
                myActiveLocks[currentIndex] = _allLocks[i];
                currentIndex++;
            }
        }
        return myActiveLocks;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Sidekick {
    
    function sendAlert(address hero, uint enemies, bool armed) external {
        (bool success, ) = hero.call(abi.encodeWithSignature("alert(uint256,bool)", enemies, armed));
        require(success);
    }

    function relay(address hero, bytes memory data) external {
        (bool success, ) = hero.call(data);
        require(success);
    }
}

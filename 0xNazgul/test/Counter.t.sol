// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/FloraToken.sol";
import "../src/Setup.sol";

contract FloraTokenExploit is Test {
    FloraToken floraToken;
    Setup setup;

    // Sets up challenge
    function setUp() external {
        setup = new Setup();
        floraToken = setup.instance();
    }

    // Test to see if hack succeeded
    function testAttack() external {
        // Initial balance
        uint256 initialContractBalance = address(floraToken).balance;
        console.log("Initial FloraToken balance: %s", initialContractBalance);

        // Final balance
        uint256 finalContractBalance = address(floraToken).balance;
        console.log("Final FloraToken balance: %s", finalContractBalance);
        require(setup.isSolved(), "Attack failed!");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../contracts/Setup.sol";
import "../contracts/TheKingIsDeadLongLiveTheKing.sol";

contract TheKingIsDeadLongLiveTheKingTest {
    Setup setup;
    KingVault king;

    function setUp() external {
        setup = new Setup{value: 0.2 ether}();
        king = KingVault(address(setup.instance()));
    }

    function testAttack() external {
        // Attack

        // Check for attack success
        require(setup.isSolved(), "NOT SOLVED");
    }
}

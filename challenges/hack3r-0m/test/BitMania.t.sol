// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "forge-std/Test.sol";
import "../contracts/BitMania.sol";

contract BitManiaTest is Test {
    BitMania bitMania;

    function setUp() public {
        bitMania = new BitMania();
    }

    /**
    The attack is theoretically simple - the encrypted key is there in the contract, and the encryption alogirthm must be reversed to obtain the plaintext.

    After a long process of manually deriving it, I found the relationship between each encrypted byte and the corresponding plaintext byte. It involved carrying out the bit shifts and XORs for an arbitrary byte, and equating the result to the known encrypted byte.

    If you do this, you'd find that every bit in the encrypted byte can be deterministically expressed as some XOR over some preceding bits of the byte and correpsponding bit from previous encrypted byte.

    Here's the results:
    p0 = e0 ^ e'0
    p1 = e0 ^ e1 ^ e'1
    p2 = e1 ^ e2 ^ e'2
    p3 = e0 ^ e2 ^ e3 ^ e'3
    p4 = e0 ^ e1 ^ e3 ^ e4 ^ e'4
    p5 = e1 ^ e2 ^ e4 ^ e5 ^ e'5
    p6 = e0 ^ e2 ^ e3 ^ e5 ^ e6 ^ e'6
    p7 = e0 ^ e1 ^ e3 ^ e4 ^ e6 ^ e7 ^ e'7

    Where p is plaintext byte, e is encrypted byte for p, and e' is previous encypted byte (if any, else 0)
     */
    function testAttack() external {
        // Attack
        bytes memory encFlagDecrypted = _decryptFlag();
        console.log("FLAG: %s", string(encFlagDecrypted));

        bitMania.solveIt(string(encFlagDecrypted));

        // Check attack success
        require(bitMania.isSolved(), "NOT SOLVED");
    }

    //////////
    // HELPERS
    //////////
    function _decryptFlag()
        internal
        view
        returns (bytes memory encFlagDecrypted)
    {
        bytes memory encFlag = bitMania.encFlag();
        encFlagDecrypted = new bytes(encFlag.length);

        for (uint256 i; i < encFlag.length; i++) {
            encFlagDecrypted[i] = _getPlaintextByte(
                i == 0 ? bytes1(0) : encFlag[i - 1],
                encFlag[i]
            );
        }
    }

    /**
    @dev Gets plaintext byte for a given encrypted byte
    @param _encBytePrev Previous encrypted byte, if any
    @param _encByteCurr Current encrypted byte
    @return plaintextByte Plaintext byte
     */
    function _getPlaintextByte(bytes1 _encBytePrev, bytes1 _encByteCurr)
        internal
        pure
        returns (bytes1 plaintextByte)
    {
        plaintextByte =
            _getPlaintextByteWithNthBit(_encBytePrev, _encByteCurr, 0) |
            _getPlaintextByteWithNthBit(_encBytePrev, _encByteCurr, 1) |
            _getPlaintextByteWithNthBit(_encBytePrev, _encByteCurr, 2) |
            _getPlaintextByteWithNthBit(_encBytePrev, _encByteCurr, 3) |
            _getPlaintextByteWithNthBit(_encBytePrev, _encByteCurr, 4) |
            _getPlaintextByteWithNthBit(_encBytePrev, _encByteCurr, 5) |
            _getPlaintextByteWithNthBit(_encBytePrev, _encByteCurr, 6) |
            _getPlaintextByteWithNthBit(_encBytePrev, _encByteCurr, 7);
    }

    /**
    @dev Returns n-th bit of plaintext text byte, in a byte that looks like 000X0000, where X is the required plaintext bit set at n-th bit location of the byte
    @param _encBytePrev Previous encrypted byte, if any
    @param _encByteCurr Current byte
    @param _n Position number (0 started) of the bit
    @return plaintextByteWithNthBit Plaintext byte that looks like 000X0000, where X is the required plaintext bit set at n-th bit location of the byte
     */
    function _getPlaintextByteWithNthBit(
        bytes1 _encBytePrev,
        bytes1 _encByteCurr,
        uint8 _n
    ) internal pure returns (bytes1 plaintextByteWithNthBit) {
        bytes1 intermediateByteWithNthBit = _getIntermediateByteWithNthBit(
            _encByteCurr,
            _n
        );

        plaintextByteWithNthBit =
            intermediateByteWithNthBit ^
            _moveNthBitToNewPosition(_encBytePrev, _n, _n);
    }

    /**
    @dev Returns n-th bit of intermediate text byte, in a byte that looks like 000X0000, where X is the required intermediate bit set at n-th bit location of the byte
    @param _encByteCurr Encrypted byte (current)
    @param _n Position number (0 started) of the bit
    @return intermediateByteWithNthBit A byte that looks like 000X0000, where X is the required plaintext bit set at n-th bit location of the byte
     */
    function _getIntermediateByteWithNthBit(bytes1 _encByteCurr, uint8 _n)
        internal
        pure
        returns (bytes1 intermediateByteWithNthBit)
    {
        if (_n == 0) {
            intermediateByteWithNthBit = _moveNthBitToNewPosition(
                _encByteCurr,
                0,
                0
            );
        } else if (_n == 1) {
            intermediateByteWithNthBit =
                _moveNthBitToNewPosition(_encByteCurr, 0, 1) ^
                _moveNthBitToNewPosition(_encByteCurr, 1, 1);
        } else if (_n == 2) {
            intermediateByteWithNthBit =
                _moveNthBitToNewPosition(_encByteCurr, 1, 2) ^
                _moveNthBitToNewPosition(_encByteCurr, 2, 2);
        } else if (_n == 3) {
            intermediateByteWithNthBit =
                _moveNthBitToNewPosition(_encByteCurr, 0, 3) ^
                _moveNthBitToNewPosition(_encByteCurr, 2, 3) ^
                _moveNthBitToNewPosition(_encByteCurr, 3, 3);
        } else if (_n == 4) {
            intermediateByteWithNthBit =
                _moveNthBitToNewPosition(_encByteCurr, 0, 4) ^
                _moveNthBitToNewPosition(_encByteCurr, 1, 4) ^
                _moveNthBitToNewPosition(_encByteCurr, 3, 4) ^
                _moveNthBitToNewPosition(_encByteCurr, 4, 4);
        } else if (_n == 5) {
            intermediateByteWithNthBit =
                _moveNthBitToNewPosition(_encByteCurr, 1, 5) ^
                _moveNthBitToNewPosition(_encByteCurr, 2, 5) ^
                _moveNthBitToNewPosition(_encByteCurr, 4, 5) ^
                _moveNthBitToNewPosition(_encByteCurr, 5, 5);
        } else if (_n == 6) {
            intermediateByteWithNthBit =
                _moveNthBitToNewPosition(_encByteCurr, 0, 6) ^
                _moveNthBitToNewPosition(_encByteCurr, 2, 6) ^
                _moveNthBitToNewPosition(_encByteCurr, 3, 6) ^
                _moveNthBitToNewPosition(_encByteCurr, 5, 6) ^
                _moveNthBitToNewPosition(_encByteCurr, 6, 6);
        } else if (_n == 7) {
            intermediateByteWithNthBit =
                _moveNthBitToNewPosition(_encByteCurr, 0, 7) ^
                _moveNthBitToNewPosition(_encByteCurr, 1, 7) ^
                _moveNthBitToNewPosition(_encByteCurr, 3, 7) ^
                _moveNthBitToNewPosition(_encByteCurr, 4, 7) ^
                _moveNthBitToNewPosition(_encByteCurr, 6, 7) ^
                _moveNthBitToNewPosition(_encByteCurr, 7, 7);
        }
    }

    /**
    @dev Moves a bit in byte to another location; result is a byte that looks like 000X0000, where X is at the chosen destination
    @param _encByte Byte input
    @param _nFrom Bit position to move from
    @param _nTo Bit position to move into
    @return byteWithBitPositioned A byte that looks like 000X0000, where X is at _nTo-th location
     */
    function _moveNthBitToNewPosition(
        bytes1 _encByte,
        uint8 _nFrom,
        uint8 _nTo
    ) internal pure returns (bytes1 byteWithBitPositioned) {
        // Shift right all the way to set required bit at n=7
        byteWithBitPositioned = _encByte >> (uint8(7) - _nFrom);

        // Shift left all the way to set required bit at n=0
        byteWithBitPositioned = byteWithBitPositioned << uint8(7);

        // Shift right to n = _nTo
        byteWithBitPositioned = byteWithBitPositioned >> _nTo;
    }
}

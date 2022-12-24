// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.3;
import "@openzeppelin/contracts/access/Ownable.sol";

/** @title Casino
 *  @dev This contract implement is a casino style game contract with an ERC20 like interface.
 * Users can deposit/withdraw ether in the contract to mint new tokens.
 * Players can call jackpot function to try to guess the random number.
 * Each round consists of 10 attempts
 * If the random number is not guesses within 10 attempts, contract choose randomly a winner amongst 10 players.
 * The player get 75% share of the amount played, 15% goes to the jackpot and 10% to investors.
 * The 10% is distributed as increment in the value of the token.
 * If the random number is guessed the winner gets the total amount bet on the round + jackpot + a share of investors tokens.
 * When random number is guessed contract is closed and investors can withdraw their tokens
 * Contract has an owner to restart the new round.
 * To play users can choose a chance representing the chance for them to win and stake accordingly
 */
contract Casino is Ownable {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 constant uintOfHashOfSecret =53880821709425663382224656414504720551041963312028604496005163007221397123198;
    uint256 public totalDeposits;
    uint256 public totalSupply;
    uint256 public totalPrize;
    uint256 public totalJackpot;
    uint256 public tokenToWeiValue;
    uint256 public lastWinTime;
    uint256 public attemptNumber;
    uint256 public roundNumber;

    bool public finished;
    bool public gameOn;

    address public lastWinner;
    Ticket[10] tickets;

    struct Ticket {
        address player;
        uint256 timestamp;
        uint256 chance;
    }

    event Deposit(address depositor, uint256 amount);
    event Withdrawal(address withdrawer, uint256 amount);
    event Received(address depositor, uint256 amount);
    event Won(address winner, uint256 num, uint256 prize);
    event Jackpot(address winner, uint256 chance, uint256 num);
    event Round(uint256 round);

    constructor() {
        tokenToWeiValue = 1 ether;
        lastWinTime = block.timestamp;
        roundNumber = 1;
        gameOn = true;
    }
    /**
     * @dev Deposit Eth and mint token.
     */
    function deposit() external payable {
        require(msg.value >= 1 ether / 10, "Low investment");
        require(!finished, "We are ruined, withdraw your money and leave");
        require(gameOn, "Wait for token value update");
        require(attemptNumber < 6, "Wait please");
        uint256 amount = msg.value;
        balanceOf[msg.sender] += (amount * 1 ether) / tokenToWeiValue;
        totalDeposits += amount;
        totalSupply += (amount * 1 ether) / tokenToWeiValue;
        emit Deposit(msg.sender, amount);
    }
    /**
     * @dev Burn token and withdraw Eth.
     */
    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        uint256 transferAmount = (amount * tokenToWeiValue) / 1 ether;
        totalSupply -= amount;
        totalDeposits -= transferAmount;
        payable(msg.sender).transfer(transferAmount);
        emit Withdrawal(msg.sender, amount);
    }

    function approve(address guy, uint256 wad) external returns (bool) {
        allowance[msg.sender][guy] = wad;
        return true;
    }

    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) internal returns (bool) {
        require(balanceOf[src] >= wad);

        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
            require(allowance[src][msg.sender] >= wad);

            allowance[src][msg.sender] -= wad;
        }
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        return true;
    }
    /**
     * @dev Play a game and guess number.
     */
    function jackpot(uint256 num, uint256 chance) external payable {
        require(!finished, "Over");
        require(gameOn && attemptNumber < 10, "Wait for next round");
        require(chance > 0 && chance < 6, "!chance");
        require( msg.value == chance * 1 ether + (chance * ((roundNumber - 1) * 1 ether)) / 10, "Incorrect amount");
        uint256 amount = msg.value;
        totalPrize += amount;
        tickets[attemptNumber] = Ticket(msg.sender, block.timestamp, chance);
        attemptNumber += 1;
        num = _hash(num);

        if (_abs(num, uintOfHashOfSecret) <= 10 * chance) {
            lastWinner = msg.sender;
            finished = true;
            uint256 transferAmount = (totalDeposits * chance) / 10 + totalPrize + totalJackpot;
            totalDeposits -= (totalDeposits * chance) / 10;
            tokenToWeiValue -= (tokenToWeiValue * chance) / 10;
            lastWinTime = block.timestamp;
            payable(msg.sender).transfer(transferAmount);
            emit Jackpot(msg.sender, chance, num);
        } else if (attemptNumber == 10) {
            address winner = _getWinner();
            lastWinner = winner;
            uint256 transferAmount = (totalPrize * 75) / 100;
            lastWinTime = block.timestamp;
            delete tickets;
            gameOn = false;
            payable(winner).transfer(transferAmount);
            emit Won(winner, num, transferAmount);
        }
    }
    /**
     * @dev Restart new round .
     */
    function restart() external onlyOwner {
        require(block.timestamp > lastWinTime + 6 hours, "Cool down period");
        require(address(this).balance == totalDeposits + totalJackpot + (totalPrize * 25) / 100, "round still on");
        totalJackpot += (totalPrize * 15) / 100;
        totalDeposits = address(this).balance - totalJackpot;
        tokenToWeiValue = (totalDeposits * 1 ether) / totalSupply;
        totalPrize = 0;
        gameOn = true;
        roundNumber += 1;
        attemptNumber = 0;
        emit Round(roundNumber);
    }
    /**
     * @dev Internal function to find winner after round finish.
     */
    function _getWinner() internal view returns (address) {
        uint256 random = _random();
        uint256 totalChances;
        uint256[10] memory chancesCumSum;
        for (uint256 i = 0; i < tickets.length; i++) {
            totalChances += tickets[i].chance;

            chancesCumSum[i] = totalChances;
        }
        random = random % totalChances;

        if (random < chancesCumSum[0]) {
            return tickets[0].player;
        }

        uint256 hi = chancesCumSum.length - 1;
        uint256 lo = 1;

        while (lo <= hi) {
            uint256 mid = lo + (hi - lo) / 2;

            if (random < chancesCumSum[mid]) {
                hi = mid - 1;
            } else if (random > chancesCumSum[mid]) {
                lo = mid + 1;
            } else {
                return tickets[mid + 1].player;
            }
        }

        return tickets[lo].player;
    }
    /**
     * @dev random number used to find winner.
     * Consider its implemented using Chainlink VRF
     */
    function _random() internal view returns (uint256) {
        bytes32 _hash;
        for (uint256 i = 0; i < tickets.length; i++) {
            _hash = keccak256(
                abi.encodePacked( _hash, tickets[i].player, tickets[i].timestamp, tickets[i].chance, tickets[i].player.balance)
            );
        }

        return uint256(_hash);
    }
    
    function _hash(uint256 number) internal pure returns (uint256) {
        bytes32 numberHash = keccak256(abi.encode(number));
        return uint256(numberHash);
    }

    function _abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }
}

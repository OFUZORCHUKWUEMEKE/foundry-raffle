// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRfv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    // Errors

    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    // Type Declarations
    enum RaffleState{
        OPEN,
        CALCULATING
    }

    // STATE VARIABLES
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint256 private immutable i_entranceFee;
    uint32 private constant NUM_WORDS=1;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionid;
    bytes32 private immutable i_keyHash;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    uint32 private immutable i_callbackGasLimit;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscribtionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        // s_vrfCoordinator.requestRandomWords();
        i_keyHash = gasLane;
        i_subscriptionid = subscribtionId;
        i_callbackGasLimit=callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee,"Not enough Eth sent! ");
        // require(msg.value >= i_entranceFee,SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if(s_raffleState !=RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }
    /**
     * @dev This is the function that the chainlink nodes will call to use 
     * @param - ignored
     */

    function checkUpKeep(bytes memory) public view returns(bool upkeepNeeded , bytes memory){
        bool timeHasPassed = ((block.timestamp -s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = s_players.length >0;
        bool hasPlayers = s_players.length >0 ;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded,"");

    }

    //  1. Get a random number
    //  2. Use random number to pick a player
    //  3. Be automatically called
    function performUpkeep(bytes calldata) external {
        // check to see if enpugh time has passed
        (bool upkeepNeeded,) = checkUpKeep("");
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
        }
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionid,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit:  i_callbackGasLimit,
                numWords:NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
            uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    // Getters Functions
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    functio getPlayer(uint256 indexOfPlayer)external view returns(address){
        return s_players[indexOfPlayer];
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override{
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        (bool success,) = recentWinner.call{value:address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }
}

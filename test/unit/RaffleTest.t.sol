// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {Vm} from "forge-std/Vm.sol";
contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLeft;
    uint256 subscriptionId;

    address public PLAYER = makeAddr("PLAYER");
    uint256 public constant STARTING_POINT_BALANCE =10 ether;

    function setUp()external{
        DeployRaffle deployer = new DeployRaffle();
        (raffle,helperConfig) = deployer.deployContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCordinator = config.vrfCordinator;
        gasLane = config.gasLane;
        callbackGasLeft= config.callbackGasLeft;
        subscriptionId = config.subscriptionId;
        vm.deal(PLAYER,STARTING_POINT_BALANCE);
    }

    function testRaffleState()public view {
        assert(raffle.getRaffleState()== Raffle.RaffleState.OPEN);
    }

    function testRaffleWhenPayisNotEnough() public{
        vm.prank(PLAYER);

        vm.expectRevert(Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleTestWhenTheyEnter() public{
        vm.prank(PLAYER);

        raffle.enterRaffle{value:entranceFee}();

        address playerRecorded = raffle.getPlayer();
        assert(playerRecorded==PLAYER);
    }  
     modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        _;
    }

        modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }



    function testDontAllowPlayersToEnterWhileCalculating() public raffleEntered{
       

        raffle.performUpkeep("");
        vm.expectRevert();
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
    }

    function testCheckUpKeepReturnsFalseIfNoBalance()public{
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool !upkeepNeeded) = raffle.checkUpKeep("");

        assert(!upkeepNeeded);

    }

       function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

      function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered{
        // Arrange
      

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // requestId = raffle.getLastRequestId();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1); // 0 = open, 1 = calculating
    }

    
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public raffleEntered  {
        // Arrange
        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // vm.mockCall could be used here...
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(0, address(raffle));

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(1, address(raffle));
    }

}
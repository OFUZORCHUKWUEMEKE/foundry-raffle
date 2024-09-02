// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";

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

    function testDontllowPlayersToEnterWhileCalculating()public{
        vm.prank(PLAYER);

        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp + interval +1 );
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        vm.expectRevert();
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
    }


}
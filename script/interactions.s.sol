// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract Interactions is Script{

    HelperConfig helperConfig = new HelperConfig()

    function createSubscriptionUsingConfig() public returns (uint256,address){
        address vrfCordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256,) = createSubscription();
          return (subId,vrfCordinator);
    }

    function createSubscription(address vrfCordinator)public returns (uint256,address) {
        console.log("creating subscription on chain Id :", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription ID is ",subId);
        console.log("Please up your subscription");
        return (subId,vrfCordinator);
    }

    function run () public{
        createSubscriptionUsingConfig()
    }
}
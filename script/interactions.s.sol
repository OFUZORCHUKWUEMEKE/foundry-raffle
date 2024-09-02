// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Script,Console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "./HelperConfig.s.sol";
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

contract FundSubscription is Script,CodeConstants{

    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address link = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinatorV2_5 = updatedVRFv2;
            console.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinatorV2_5);
        }

        fundSubscription(vrfCoordinatorV2_5, subId, link, account);
    }

     function fundSubscription(address vrfCoordinatorV2_5, uint256 subId, address link, address account) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinatorV2_5);
        console.log("On ChainID: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(link).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(link).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {CreateSubscription} from "./interactions.s"
contract DeployRaffle is Script{
    function run () public{}

    function deployContract() public returns(Raffle,HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subcriptionId==0){
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subcriptionId,config.vrfCordinator) = createSubscription.createSubscription(config.vrfCordinator);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle({
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subcriptionId,
            config.callbackGasLimit
        })
        vm.stopBroadcast();
        return (Raffle,helperConfig);
    }
}
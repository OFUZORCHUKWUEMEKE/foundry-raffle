// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants{

    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;

    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;
    
    uint256 public constant ETH_SEPOLIA_CHAIN_ID =1115511;
    uint256 public constant LOCAL_CHAIN_ID =31337;
}

contract HelperConfig is CodeConstants, Script{

    error HelperConfig__InvalidChainId();
    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLeft;
        uint256 subscriptionId;
    }
    constructor(){
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId =>NetworkConfig) public networkConfigs;

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoordinator != address(0)){
            return networkConfigs[chainId];
        }else if (chainId == LOCAL_CHAIN_ID){
            // 
        }else{
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig()public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee:0.01 ether,
            interval:30,
            vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1,
            gasLane:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
           callbackGasLeft:500000,
           subscriptionId:0
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory){
        if(localNetworkConFig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }
        vm.startBroadcast();
       VRFCoordinatorV2_5Mock vrfCordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,MOCK_GAS_PRICE_LINK,MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        localNetworkConfig= NetworkConfig({
            entranceFee:0.01 ether,
            interval:30,
            vrfCordinator:address(vrfCordinatorMock),
            gasLane:0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6,
            callBackGasLimit:500000,
            subscriptionId:0
        });
    }



    
}
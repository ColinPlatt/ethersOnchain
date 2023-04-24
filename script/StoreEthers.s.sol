// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@holic/ethfs/FileStore.sol";

contract StoreEthersScript is Script {
    
    string[] ethersRawChunks;

    function setUp() public {

        string memory path = string.concat(vm.projectRoot(), "/script/files/ethers_6_3_1.js");
        string memory rawFile = vm.readFile(path);

                
    }    

    function run() public {
        
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@holic/ethfs/FileStore.sol";
import "@holic/ethfs/ContentStore.sol";

contract StoreEthersScript is Script {
    
    string path = string.concat(vm.projectRoot(), "/script/files/ethers_6_3_0.js");
    uint256 goerliFork;
    string GOERLI_RPC_URL = vm.envString("GOERLI_RPC_URL");
    uint256 PK = vm.envUint("PK");
    address addrContentStore = vm.envAddress("ContentStore");
    address addrFileStore = vm.envAddress("FileStore");
    address addrFileStoreFrontend = vm.envAddress("FileStoreFrontend");
    string file_name = "ethers 6_3_0.umd.min.js";

    FileStore public deployedFileStore;
    ContentStore public deployedContentStore;

    string[] ethersRawChunks;
    uint256 constant CHUNK_SIZE = 24_000;

    function _loadFile() internal {
        string memory rawFile = vm.readFile(path);

        uint256 numChunks = bytes(rawFile).length / CHUNK_SIZE + 1;
        bytes memory rawFileBytes = bytes(rawFile);
        uint remainingBytes = bytes(rawFile).length;

        for(uint256 i = 0; i < numChunks; i++) {
            uint len;
            if(remainingBytes >= CHUNK_SIZE) {
                len = CHUNK_SIZE; 
                remainingBytes -= CHUNK_SIZE;
            } else {
                len = remainingBytes;
                remainingBytes = 0;
            }

            bytes memory tempChunk = new bytes(len);

            for(uint j = 0; j<len; j++) {
                tempChunk[j] = rawFileBytes[i * CHUNK_SIZE + j];
            }
            ethersRawChunks.push(string(tempChunk));
        }        
    }

    function _createEthersFile() internal {
        // load checksums into memory
        bytes32[] memory checksums = new bytes32[](ethersRawChunks.length);

        // create content
        for(uint256 i = 0; i < ethersRawChunks.length; i++) {
            (checksums[i], ) = deployedContentStore.addContent(bytes(ethersRawChunks[i]));
        }

        // create file
        deployedFileStore.createFile(file_name, checksums);

    }



    function setUp() public {

        _loadFile();

        deployedFileStore = FileStore(addrFileStore);
        deployedContentStore = ContentStore(addrContentStore);

    }    

    function run() public {
        vm.startBroadcast(PK);
            _createEthersFile();
        vm.stopBroadcast();

        assert(deployedFileStore.fileExists(file_name));
    }
}

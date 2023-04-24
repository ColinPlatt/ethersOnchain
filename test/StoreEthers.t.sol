// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@holic/ethfs/FileStore.sol";
import "@holic/ethfs/ContentStore.sol";

contract StoreEthersTest is Test {

    string path = string.concat(vm.projectRoot(), "/script/files/ethers_6_3_0.js");
    uint256 goerliFork;
    string GOERLI_RPC_URL = vm.envString("GOERLI_RPC_URL");
    address addrContentStore = vm.envAddress("ContentStore");
    address addrFileStore = vm.envAddress("FileStore");
    address addrFileStoreFrontend = vm.envAddress("FileStoreFrontend");
    string file_name = "ethers_6_3_0.umd.min.js";

    FileStore public deployedFileStore;
    ContentStore public deployedContentStore;

    string[] ethersRawChunks;
    bytes32[] ethersChecksums;
    uint256 constant CHUNK_SIZE = 24_000;

    function setUp() public {
        goerliFork = vm.createSelectFork(GOERLI_RPC_URL);
        _loadFile();

        deployedFileStore = FileStore(addrFileStore);
        deployedContentStore = ContentStore(addrContentStore);
    }    

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
            ethersChecksums.push(keccak256(tempChunk));
        }        
    }

    function _createEthersFile() internal {
        // load checksums into memory
        bytes32[] memory checksums = new bytes32[](ethersChecksums.length);

        // create content
        for(uint256 i = 0; i < ethersChecksums.length; i++) {
            (checksums[i], ) = deployedContentStore.addContent(bytes(ethersRawChunks[i]));
            assertEq(checksums[i], ethersChecksums[i], "checksums do not match");
        }

        // create file
        deployedFileStore.createFile(file_name, checksums);

    }

    function testFile() public {
        string memory rawFile = vm.readFile(path);
        
        string memory ethersRawChunksJoined;
        for(uint256 i = 0; i < ethersRawChunks.length; i++) {
            ethersRawChunksJoined = string.concat(ethersRawChunksJoined, ethersRawChunks[i]);
        }
        assertEq(rawFile, ethersRawChunksJoined, "output does not match input");
    }

    function testCreateFile() public {
        _createEthersFile();
        assert(deployedFileStore.fileExists(file_name));
    }

    function testRecreateFile() public {
        _createEthersFile();
        vm.startPrank(address(deployedFileStore.owner()));
            deployedFileStore.deleteFile(file_name);
        vm.stopPrank();

        assert(!deployedFileStore.fileExists(file_name));

        // create file
        bytes32[] memory checksums = ethersChecksums;
        deployedFileStore.createFile(file_name, checksums);
        assert(deployedFileStore.fileExists(file_name));
        
    }

}

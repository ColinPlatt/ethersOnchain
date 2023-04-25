// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@holic/ethfs/FileStore.sol";
import "@holic/ethfs/FileStoreFrontend.sol";
import "@holic/ethfs/ContentStore.sol";

contract StoreEthersTest is Test {

    string path = string.concat(vm.projectRoot(), "/script/files/ethers_6_3_0.js");
    uint256 goerliFork;
    string GOERLI_RPC_URL = vm.envString("GOERLI_RPC_URL");
    address addrContentStore = vm.envAddress("ContentStore");
    address addrFileStore = vm.envAddress("FileStore");
    address addrFileStoreFrontend = vm.envAddress("FileStoreFrontend");
    string file_name = "ethers_6_3_0.umd.min.js_test"; // have to change as it is now deployed

    FileStore public deployedFileStore;
    ContentStore public deployedContentStore;
    FileStoreFrontend public deployedFileStoreFrontend;

    string[] ethersRawChunks;
    bytes32[] ethersChecksums;
    uint256 constant CHUNK_SIZE = 24_000;

    function setUp() public {
        goerliFork = vm.createSelectFork(GOERLI_RPC_URL);
        _loadFile();

        deployedFileStore = FileStore(addrFileStore);
        deployedContentStore = ContentStore(addrContentStore);
        deployedFileStoreFrontend = FileStoreFrontend(addrFileStoreFrontend);
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

    function testFile() public {
        string memory fullFilePath = string.concat(vm.projectRoot(), "/script/files/ethers_6_3_0.js");
        string memory rawFullFile = vm.readFile(fullFilePath);
        
        string memory ethersRawChunksJoined;
        for(uint256 i = 0; i < ethersRawChunks.length; i++) {
            ethersRawChunksJoined = string.concat(ethersRawChunksJoined, ethersRawChunks[i]);
        }
        assertEq(rawFullFile, ethersRawChunksJoined, "output does not match input");
        assertEq(rawFullFile, deployedFileStoreFrontend.readFile(IFileStore(addrFileStore), "ethers_6_3_0.umd.min.js"), "frontend output does not match input");


    }

    function testCreateFile() public {
        _createEthersFile();
        assert(deployedFileStore.fileExists(file_name));
    }

    function testDeployedEthers() public {
        string memory deployedLib = deployedFileStoreFrontend.readFile(IFileStore(addrFileStore), "ethers_6_3_0.umd.min.js");

        vm.writeFile("test/output/ethers_deployed.js", deployedLib);
    }

}

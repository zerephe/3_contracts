// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ILayer {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function burn(uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

contract MetamorphicTrack is ERC721A, Ownable{
    string private baseURI;
    ILayer layerContract;

    constructor(address layerAddress) ERC721A("Metamorphic by DAILLY", "METAMORPHIC") {
        layerContract = ILayer(layerAddress);
    }
    
    function merge(uint256[] calldata layers, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, layers));
        bytes32 hashedMessage = hashMessage(message);
        address addr = ecrecover(hashedMessage, v, r, s);

        require(addr == msg.sender, "Invalid sig!");
        require(layers.length == 3, "Invalid layer count!");
        
        for(uint256 i = 0; i < layers.length; i++) {
            require(layerContract.ownerOf(layers[i]) == msg.sender, "Not owned layer!");
        }

        for(uint256 i = 0; i < layers.length; i++) {
            layerContract.burn(layers[i]);
        }
        
        _mint(msg.sender, 1);
    }

    function merge(uint256[] calldata layers) external {
        require(layers.length == 3, "Invalid layer count!");

        for(uint256 i = 0; i < layers.length; i++) {
            require(layerContract.ownerOf(layers[i]) == msg.sender, "Not owned layer!");
        }

        for(uint256 i = 0; i < layers.length; i++) {
            layerContract.burn(layers[i]);
        }
        
        _mint(msg.sender, 1);
    }

    function hashMessage(bytes32 message) private pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    function setLayerContractAddress(address newLayerAddress) external onlyOwner{
        layerContract = ILayer(newLayerAddress);
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
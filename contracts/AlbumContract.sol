// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ITrack {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function burn(uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

contract MetamorphicAlbum is ERC721A, Ownable{
    string private baseURI;
    ITrack trackContract;

    constructor(address trackAddress) ERC721A("Metamorphic Album", "METAALBUM") {
        trackContract = ITrack(trackAddress);
    }
    
    function merge(uint256[] calldata tracks, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, tracks));
        bytes32 hashedMessage = hashMessage(message);
        address addr = ecrecover(hashedMessage, v, r, s);

        require(addr == msg.sender, "Invalid sig!");
        require(tracks.length == 10, "Invalid track count!");
        
        for(uint256 i = 0; i < tracks.length; i++) {
            require(trackContract.ownerOf(tracks[i]) == msg.sender, "Not owned layer!");
        }

        for(uint256 i = 0; i < tracks.length; i++) {
            trackContract.burn(tracks[i]);
        }
        
        _mint(msg.sender, 1);
    }

    function merge(uint256[] calldata tracks) external {
        require(tracks.length == 10, "Invalid track count!");
        
        for(uint256 i = 0; i < tracks.length; i++) {
            require(trackContract.ownerOf(tracks[i]) == msg.sender, "Not owned layer!");
        }

        for(uint256 i = 0; i < tracks.length; i++) {
            trackContract.burn(tracks[i]);
        }
        
        _mint(msg.sender, 1);
    }

    function hashMessage(bytes32 message) private pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    function setTrackContractAddress(address newTrackAddress) external onlyOwner{
        trackContract = ITrack(newTrackAddress);
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
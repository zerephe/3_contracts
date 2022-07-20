// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MetamorphicLayer is ERC721A, Pausable, Ownable{
    bytes32 private merkleRoot;

    string private baseURI;
    uint256 public price = 0.3 ether;
    uint256 public maxSupply = 0;

    struct Allowed {
        address user;
        uint256 price;
        uint256 allowedAmount;
        uint256 maxAllowed;
    }

    mapping(address => Allowed) public allowList;
    mapping(address => uint256) public minted;
    
    // constructor(string memory _baseUri, bytes32 _merkleRoot) ERC721A("Metamorphic by DAILLY", "METAMORPHIC") {
    //     merkleRoot = _merkleRoot;
    //     baseURI = _baseUri;
    // }

    constructor() ERC721A("Metamorphic Layer", "METALAYER") {

    }

    function listMint(bytes32[] calldata _merkelProof, uint256 quantity) external payable whenNotPaused {
        //checking if user(s) claimed their nft
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkelProof, merkleRoot, leaf), "Not allowed!");
        require(maxSupply + quantity <= 3600, "Max supply exceeded!");
        require(allowList[msg.sender].allowedAmount - quantity >= 0, "Allowed amount exceeded!");
        require(msg.value >= allowList[msg.sender].price * quantity, "Not enough eth!");

        allowList[msg.sender].allowedAmount -= quantity;
        maxSupply += quantity;

        _mint(msg.sender, quantity);
    }
    
    function mint(uint256 quantity, uint8 v, bytes32 r, bytes32 s) external payable whenNotPaused {
        require(msg.value >= price * quantity, "Not enough eth!");
        require(allowList[msg.sender].maxAllowed == 0, "List user minting!");
        require(maxSupply + quantity <= 3600, "Max supply exceeded!");
        require(minted[msg.sender] + quantity <= 30, "Mint limit exceeded!");

        bytes32 message = keccak256(abi.encodePacked(msg.sender, quantity, price));
        bytes32 hashedMessage = hashMessage(message);
        address addr = ecrecover(hashedMessage, v, r, s);

        require(addr == msg.sender, "Invalid sig!");
        
        maxSupply += quantity;
        minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function teamMint(uint256 quantity) external {
        maxSupply += quantity;
        _mint(msg.sender, quantity);
    }

    function initlist(Allowed[] memory allowedList) external onlyOwner {
        for(uint256 i = 0; i < allowedList.length; i++){
            allowList[allowedList[i].user].price = allowedList[i].price;
            allowList[allowedList[i].user].allowedAmount = allowedList[i].allowedAmount;
            allowList[allowedList[i].user].maxAllowed = allowedList[i].maxAllowed;
        }
    }

    function hashMessage(bytes32 message) private pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    function setPriceInWei(uint256 newPrice) external onlyOwner {
        price = newPrice;
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

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function withdraw(address payable receiverAddress, uint _withdrawAmount) external onlyOwner {
        require(address(this).balance >= _withdrawAmount, "Low balance!");
        
        receiverAddress.transfer(_withdrawAmount); 
    }
}

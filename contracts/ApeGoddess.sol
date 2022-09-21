//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ApeGoddess is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;

    string public hiddenMetadataURI = "ipfs://Qmd6o1c8ap6i5d2ByYkMuCdHFs9qRKmzdTHuU73eHns5AL";
    string public baseURI = "";

    enum MintStatus {
        Not_Live,
        Whitelist_Mint,
        Public_Mint
    }
    MintStatus public mintStatus;

    uint256 public mintPrice = 0.01 ether;
    uint256 public maxSupply = 100;
    uint256 public maxPerWallet = 3;

    bool public revealed = false;

    mapping(address => bool) public whitelistClaimed;

    constructor() ERC721A("Ape Goddess", "AG") {
        mintStatus = MintStatus.Not_Live;
    }

    modifier mintCompliance(uint256 _quantity) {
        require(_quantity > 0 && (_quantity + _numberMinted(msg.sender) <= maxPerWallet), "Invalid Amount");
        require(totalSupply() + _quantity <= maxSupply, "Sold Out");
        require(msg.value >= (mintPrice * _quantity), "Incorrect Mint Price");
        _;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();

        if(revealed == false) {
            return hiddenMetadataURI;
        } else {
            return bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : "";
        }
    }

    function whitelistMint(uint256 _quantity, bytes32[] calldata proof) external payable mintCompliance(_quantity) {
        require(mintStatus == MintStatus.Whitelist_Mint, "Whitelist mint not live");
        require(!whitelistClaimed[msg.sender], "already claimed whitelist");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf));

        if(_numberMinted(msg.sender) == maxPerWallet) {
            whitelistClaimed[msg.sender] = true;
        }

        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable mintCompliance(_quantity) {
        require(mintStatus == MintStatus.Public_Mint, "Public mint not Live");
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external payable onlyOwner{
        require((_quantity + _numberMinted(owner())) <= 10, "Exceeded limit for owner");
        _safeMint(owner(), _quantity);
    }

    function setHiddenMetadataURI(string memory _hiddenMetadataURI) external onlyOwner {
        hiddenMetadataURI = _hiddenMetadataURI;
    }

    function setRevealed() external onlyOwner{
        revealed = !revealed;
    }

    function enableWhitelistMint() external onlyOwner {
        mintStatus = MintStatus.Whitelist_Mint;
    }

    function enablePublicMint() external onlyOwner {
        mintStatus = MintStatus.Public_Mint;
    }

    function _startTokenId() internal view virtual override returns(uint256) {
        return 1;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function withdrawETH() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "Nothing to withdraw");
        (bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
        require(sent, "Transaction failed");
    } 

    receive() external payable {}

    fallback() external payable {}
}
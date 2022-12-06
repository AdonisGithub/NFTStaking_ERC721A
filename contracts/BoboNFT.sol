//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BOBONFT is ERC721A, Ownable {
    uint256 MAX_MINTS = 30;
    uint256 MAX_SUPPLY = 11070;
    uint256 public mintRate = 0.00001 ether;
    bool public saleEnable = true;
    mapping(address => uint) public ref; 


    // Royalties address
    address public royaltyAddress = 0x4eAa723Ff2b6B72E9AB508d4b5420A5701d4845c;

    // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0) 10% artist 90% flipper
    uint256 private royaltyBasisPoints = 100; // 10%

    event RoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
    event MintedNft(uint256 indexed _quantity, address add);

    string public baseURI ="";

    address signerAddress = 0x5B978A9Fa87Eab82afc8aBFcC62E4844E976f77E;

    constructor() ERC721A("go", "go") {}
    // Token Id start from 1 
    function _startTokenId()  internal pure override returns(uint256){
        return 1;
    }

    function TotalBurned() public view returns(uint256) {
        return _totalBurned();

    }

    function next() public view returns(uint256){
        return _nextTokenId();
    }

    function toggleSale(bool status) public onlyOwner {
        require(saleEnable !=status);
        saleEnable = status;
    }

    function getSigner(address _toAddress, uint _quantity, address _refAddrses, bytes memory signature) pure internal returns(address) {
        bytes32 hash = keccak256(abi.encodePacked(_toAddress, _quantity, _refAddrses));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(message, signature);
        return signer;
    }

    function mint(uint256 quantity) external payable {

        require(
			saleEnable, 
			"Sale is not Enabled"
		);
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        _safeMint(_msgSender(), quantity);
        
        emit MintedNft(quantity,_msgSender());
    }
 
    function mintbyref(address _toAddress, uint256 _quantity, address _refAddress, bytes memory _signature) external payable {

        require(
			saleEnable, 
			"Sale is not Enabled"
		);
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            _quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(msg.value >= (mintRate * _quantity), "Not enough ether sent");
        require(_refAddress != _toAddress && _toAddress == msg.sender, "Don't cheat");
        require(getSigner(_toAddress, _quantity, _refAddress, _signature) == signerAddress, "Don't cheat");

        _safeMint(_msgSender(), _quantity);
        ref[_refAddress] += _quantity;
        
        emit MintedNft(_quantity,_msgSender());
    }
    


    function giftmint(uint256 _quantity, address add) external onlyOwner {

        require(
			saleEnable, 
			"Sale is not Enabled"
		);
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            _quantity + _numberMinted(_msgSender()) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        _safeMint(add, _quantity);
        emit MintedNft(_quantity,add);
       
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    // returns base uri 
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    // Set royalty  address
    function setRoyaltyAddress(address _address) external onlyOwner {
        royaltyAddress = _address;
    }

    // Set base URI
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

     // Set royalty basis points
  function setRoyaltyBasisPoints(uint256 _basisPoints) external onlyOwner {
    royaltyBasisPoints = _basisPoints;
    emit RoyaltyBasisPoints(_basisPoints);
  }

  // TokenURI
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'Nonexistent token');

    return string(abi.encodePacked(_baseURI(), _toString(tokenId), '.json'));
  }



}
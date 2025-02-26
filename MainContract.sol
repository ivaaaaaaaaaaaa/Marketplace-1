// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "./MainContractErrors.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721NewCollection is ERC721 {

        uint256 private tokenCounter;
        string private baseURI;
        address public mainContract;
        address private creator;
        address private mPcreator;
        
        constructor(
            string memory _name,
            string memory _symbol,
            string memory _collectionURI,
            address _creator,
            address _mPcreator,
            address _mainContract
        ) ERC721(_name, _symbol) {
            creator = _creator;
            mPcreator = _mPcreator;
            baseURI = _collectionURI;
            tokenCounter = 1;
            mainContract = _mainContract;
    }


    modifier onlyCreator() {
        require(msg.sender == mPcreator || msg.sender == creator,"Only creator can call this function");
        _;
    }

    modifier onlyMainContract() {
        require(msg.sender == mainContract, "Only mainContract can call this function");
        _;
    }

    function mint(address _to) external onlyMainContract {
        uint256 newTokenId = tokenCounter;
        _safeMint(_to, newTokenId);
        tokenCounter++;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyCreator{
        super.setApprovalForAll(operator, approved);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }
}

contract MainContract is Ownable, Errors {

    uint public idCounter = 1;
    uint private nonce = 0;

    /// @notice _id => CollectionInfo (name,symbol and more)
    mapping(uint => CollectionInfo) public collections;
    /// @notice _user => user's codes
    mapping (address => uint) private amountOfCodes;
    /// @notice _user => promoCode
    mapping (address => bytes8[]) private uniqPromoForUser;
    

    struct CollectionInfo {
        string name;
        string symbol;
        address collectionOwner;
        string collectionURI;
        uint price;
        uint quantityInStock;
        address collectionAddress;
        uint id;
    }  

    event collectionCreated (
        address newCollectionAddress,
        address collectionOwner,
        string collectionURI,
        string collectionName,
        uint price,
        uint id
    );

    event productPurchased(
        address indexed buyer,
        address indexed collectionAddress,
        uint256 price,
        uint cQuantity
    );

    event promoCodeSuccessfullyUsed(
        address indexed user,
        address indexed collectionAddress
    );
    
    
    constructor(address initialOwner) Ownable(initialOwner) {}

    //                                                     ------------------------------------------
    //                                                     -           Main Functionality           -
    //                                                     ------------------------------------------
                                                

    function buy (uint _id, uint256 _quantity) external payable {

        uint price = collections[_id].price;
        uint cQuantity = collections[_id].quantityInStock;
        require(cQuantity >= _quantity, incorrectQuantity());
        uint256 totalPrice = price * _quantity;
        require(msg.value >= totalPrice, notEnoughFunds());

        for(uint i = 0; i < _quantity; i++) {
            bytes8 promoCode = _generatePromoCode();
            uniqPromoForUser[msg.sender].push(promoCode);
        }
        amountOfCodes[msg.sender] += _quantity;


        address _collectionAddress = getAddressById(_id);
            
        _updateQuantity(_id, cQuantity - _quantity);

        payable(getOwnerByCollectionId(_id)).transfer(totalPrice);

        if(msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

         emit productPurchased(
            msg.sender,
            _collectionAddress,
            price,
            _quantity
        );
    }

    function createCollection(string calldata _name, string calldata _symbol, string calldata _collectionURI, uint _price, uint _quantityInStock) external payable {
        require(bytes(_name).length > 0 && bytes(_name).length < 64, incorrectNameLength());
        require(bytes(_symbol).length > 0 && bytes(_symbol).length < 8 , incorrectSymbolLength());
        require(bytes(_collectionURI).length > 0, incorrectURI());
        require(_price > 0, incorrectPrice());

        ERC721NewCollection collection = new ERC721NewCollection(_name, _symbol, _collectionURI, msg.sender, owner(), address(this));
        address collectionAddress = address(collection);


        CollectionInfo memory newCollection = CollectionInfo({
            name: _name,
            symbol: _symbol,
            collectionOwner: msg.sender,
            collectionURI: _collectionURI,
            price: _price,
            quantityInStock: _quantityInStock,
            collectionAddress: collectionAddress,
            id: idCounter
        });
        collections[idCounter] = newCollection;
        idCounter++;

        emit collectionCreated(collectionAddress, msg.sender, _collectionURI, _name, _price, idCounter);
    }

    function reedemCode (uint _id, bytes8 _promoCode) public payable {
        address _collectionAddress = getAddressById(_id);
        ERC721NewCollection collection = ERC721NewCollection(_collectionAddress);
        require(address(this) == collection.mainContract(), incorrectCollectionAddress());
        require(_isPromoValid(_promoCode) == true, invalidPromoCode());
        
        collection.mint(msg.sender);

        _deletePromoCode(msg.sender, _promoCode);
        amountOfCodes[msg.sender] -=1;

        emit promoCodeSuccessfullyUsed(
            msg.sender,
            _collectionAddress
        );
    }

    //                                                     ------------------------------------------
    //                                                     -           Get  functions               -
    //                                                     ------------------------------------------

    function getAddressById(uint _id) public view returns(address) {
        require(collections[_id].id != 0, collectionNotFound());
        return(collections[_id].collectionAddress);
    }

    function getPrice (uint _id) public view returns (uint) {
        require(collections[_id].id != 0, collectionNotFound());
        return(collections[_id].price);
    }

    function getQuantity (uint _id) public view returns (uint) {
        require(collections[_id].id != 0, collectionNotFound());
        return(collections[_id].quantityInStock);
    }

    function getPromo (uint _indexOfPromo, address _user) public onlyOwner view returns(bytes8) {
        require(uniqPromoForUser[_user][_indexOfPromo] != bytes8(0), incorrectIndex());
        return (uniqPromoForUser[_user][_indexOfPromo]);
    }

    function getOwnerByCollectionId (uint _id) public view returns(address){
        require(collections[_id].collectionAddress != address(0), collectionNotFound());
        return collections[_id].collectionOwner;
    }

    //                                                     ------------------------------------------
    //                                                     -           Service functions            -
    //                                                     ------------------------------------------
    
    function _findIndexByUserAddress(address _user, bytes8 _promoCode) internal view returns (uint, bool) {
        bytes8[] storage promoCodes = uniqPromoForUser[_user];
        for (uint i = 0; i < promoCodes.length ; i++) {
            if(promoCodes[i] == _promoCode) {
                return (i,true);
            }
        }
        return (0, false);
    }

    function _deletePromoCode(address _user, bytes8 _promoCode) internal {
        require(_user != address(0), incorrectAddress());
        (uint _index, bool status) = _findIndexByUserAddress(_user, _promoCode);

        if(!status) {
            revert promoCodeNotFound();
        }

        uniqPromoForUser[_user][_index] = uniqPromoForUser[_user][uniqPromoForUser[_user].length - 1];
        uniqPromoForUser[_user].pop();
    }

    function _generatePromoCode() internal returns (bytes8) {
      bytes8 random = bytes8(keccak256(abi.encode(block.timestamp,nonce ,tx.origin,nonce)));
      nonce++;
      return bytes8(random);
    }

    function _isPromoValid (bytes8 _promoCode) internal view returns (bool) {
        for (uint i = 0; i < uniqPromoForUser[msg.sender].length; i++) {
            if (uniqPromoForUser[msg.sender][i] == _promoCode) {
                return true;
            }
        }
        return false;
    }

    function _updatePrice(uint256 _id, uint256 _newPrice) private {
        require(collections[_id].id != 0, collectionNotFound());
        collections[_id].price =  _newPrice;
    }

    function _updateQuantity(uint _id, uint _newQuantity) private {
        require(collections[_id].id != 0, collectionNotFound());
        collections[_id].quantityInStock = _newQuantity;
    }
}

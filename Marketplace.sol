// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // импортируем контракт openzeppelin ERC721 для того что бы не строить велосепед заново
import "@openzeppelin/contracts/utils/Strings.sol"; // импортируем библиотеку openzeppelin Strings для удобной конкатенации строк и чисел (это нам поможет в создании URI)


contract Marketpalce is ERC721 { // импортируем
  using Strings for uint256; // импортируем

  uint256 public tokenIds; // id наших токенов, для того что бы не было повторок

  mapping ( uint256 tokenID => string tokenURI ) private tokenURIs; // хранение URI для каждого NFT
  mapping ( uint256 tokenID => uint256 price ) private prices;

  error ZeroPrice(); // пользователь указал нулевую цену при создании токена
  error NotEnoughMoney(); // пользователь отправил меньше эфира, чем было указанно  
  error FailedTransaction(); // передача денег юзеру закончилась ошибкой
  
  error TokenNotExsisit(); // токена, по такому id - не существует 
  error TokenAlredyExsisit(); // токен уже существует
  

  address public owner; // владелец контаркта

  modifier tokenNotExsist (uint _tokenId) { // проверка на то что токен вообще существует
    if (ownerOf(_tokenId) == address(0)) revert TokenNotExsisit();
    _;
  }

  event CreateNFT(uint256 indexed tokenId, string indexed  tokenURI, uint256 indexed price); // событие на создание NFT

  function _setTokenURI(uint _tokenId, string calldata _tokenURI) internal virtual tokenNotExsist(_tokenId){ // устанавливаем URI для NFT. Функция принимает id токена и сам URI.
  tokenURIs[_tokenId] = _tokenURI; 
  }

  function tokenURI( // функция для площадки, что бы на фронте считывалась эта функция и получала данные об URI определенного токена
    uint256 _tokenId
  ) public view virtual override tokenNotExsist(_tokenId) returns(string memory) {

    string memory customURI = tokenURIs[_tokenId];

    if(bytes(customURI).length > 0){
        return customURI;
    }

    string memory baseURI = _baseURI();

    return bytes(baseURI).length > 0 ? string.concat(baseURI, _tokenId.toString()) : ""; 

  }


  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    owner = msg.sender;
    _safeMint(address(this), tokenIds); // минтим одно, тестовое NFT
    tokenIds++; 
  } 

  
  function createNFT(string calldata _tokenURI, uint256 _price) public payable { 
   uint256 newTokenId = tokenIds;
   if (ownerOf(newTokenId) != address(0)) revert TokenAlredyExsisit();
   require(msg.value >= _price, NotEnoughMoney());
   require(_price > 0, ZeroPrice());
   
   _safeMint(msg.sender, newTokenId);
   _setTokenURI(newTokenId, _tokenURI);
   
   prices[newTokenId] = _price;
   tokenIds++;
   
   uint refund  = msg.value - _price;
   
   emit CreateNFT(newTokenId, _tokenURI, _price);
   
   // передача сдачи выполняется в последнюю очередь, для защиты от reetrancyAttack
   
   if(refund  > 0){
    (bool success, ) = msg.sender.call{value : refund}("");
    require(success, FailedTransaction());
   }
  }


}
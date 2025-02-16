// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";


contract Marketpalce is ERC721 { 
  using Strings for uint256; 

  /**
   * @dev createNFT => tokenIds++    
   */
  uint256 public tokenIds;

  /**
   * @dev tokenURIs[tokenID] = tokenURI 
   */
  mapping ( uint256 tokenID => string tokenURI ) private tokenURIs; // хранение URI для каждого NFT

  /**
   * @dev prices[tokenID] = price
   */
  mapping ( uint256 tokenID => uint256 price ) private prices;


  /**
   * 
   * @param tokenId айди токена
   * @param tokenURI URI ссылка
   * @param price цена на токен
   */
  event CreateNFT(uint256 indexed tokenId, string indexed  tokenURI, uint256 indexed price); // событие на создание NFT

  

  error ZeroPrice(uint price); // пользователь указал нулевую цену при создании токена
  error NotEnoughMoney(uint amount); // пользователь отправил меньше эфира, чем было указанно  
  error FailedTransaction(); // передача денег юзеру закончилась ошибкой
  error TokenNotExsisit(uint tokenId); // токена, по такому id - не существует 
  
  /**
   * @notice владелец контракта
   */
  address public owner; 

  
  /**
   * 
   * @param _tokenId токен айди
   */
  modifier tokenNotExsist (uint _tokenId) { // проверка на то что токен вообще существует
    if (ownerOf(_tokenId) == address(0)) revert TokenNotExsisit(_tokenId);
    _;
  }

  /**
   * @dev 
   * @param _tokenId токен айди
   * @param _tokenURI URI ссылка 
   */
  function _setTokenURI(uint _tokenId, string calldata _tokenURI) internal virtual tokenNotExsist(_tokenId){ // устанавливаем URI для NFT. Функция принимает id токена и сам URI.
  tokenURIs[_tokenId] = _tokenURI; 
  }


  /**
   * @dev функция для площадки, что бы на фронте считывалась эта функция и получала данные об URI определенного токена
   * @param _tokenId токен айди
   */
  function tokenURI(
    uint256 _tokenId
  ) public view virtual override tokenNotExsist(_tokenId) returns(string memory) {

    string memory customURI = tokenURIs[_tokenId];

    if(bytes(customURI).length > 0){
        return customURI;
    }

    string memory baseURI = _baseURI();

    return bytes(baseURI).length > 0 ? string.concat(baseURI, _tokenId.toString()) : ""; 
  }



  /**
   * 
   * @param name имя токена 
   * @param symbol символ токена
   */
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    owner = msg.sender;
    _safeMint(address(this), tokenIds); // минтим одно, тестовое NFT
    tokenIds++; 
  } 

  
  /**
   * 
   * @param _tokenURI URI ссылка 
   * @param _price цена токена
   */
  function createNFT(string calldata _tokenURI, uint256 _price) public payable { 
   uint256 newTokenId = tokenIds;
   require(msg.value >= _price, NotEnoughMoney(msg.value));
   require(_price > 0, ZeroPrice(_price));
   
   _mint(msg.sender, newTokenId);
   _setTokenURI(newTokenId, _tokenURI);
   
   prices[newTokenId] = _price;
   tokenIds++;
   
   uint refund  = msg.value - _price;
   
   emit CreateNFT(newTokenId, _tokenURI, _price);
   
   /**
    * @notice передача средств происходит в последний момент во избежании reentrancy attack
    * @notice если хакер захочет во второй раз зайти в эту функцию, то tokenIds увеличться на 1
    */
   
   if(refund  > 0){
    (bool success, ) = msg.sender.call{value : refund}("");
    require(success, FailedTransaction());
   }
  }


}

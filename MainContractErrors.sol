// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Errors {
    
    error NotEnoughFunds(uint price, uint getPrice);
    error PromoUsedAlredy(bool used);
    error InvalidPromo(bool redemProcess);
    error incorrectId(uint _NotId);
    // error ZeroCollectionAddress(); Немного не понял зачем нужна эта проверка, потому что во всех функциях get используется collectionNotFound
    // error TokenNotExsist(); не понял зачем нужна эта проверка. По сути, когда токен (коллекцию) создают у нее сразу появляться адресс (address collection), в функциях buy и прочих используется проверка на то, равен ли address collection = 0. Если токен не создан, то его адресс будет равен нулю, а если он существует, то чему то его адрес точно будет равен. Поэтому я особо не вижу смысла в этой проверке
    error FailedToDeployContract(bool deploy); 
    error notEnoughProductsInStock(uint inStock, uint youWant); // вроде в коде и так есть incorrectQuantity который проверяет есть ли товары на складе. Но в коммите я заменил incorrectQuantity на notEnoughProductsInStock
    error invalidPromoCode(bool ivalidPromoCode);
    error notEnoughFunds(uint totalPrice,uint youGive);
    error incorrectSymbolLength(uint minimumSymbolLength, uint youSybolLength);
    error incorrectURI(uint minimumURILength, uint youURILength);
    error incorrectPrice(uint minimumPrice, uint youPrice);
    // error incorrectQuantity(); убрал из за notEnoughProductsInStock
    error onlyMainContractError(address mainContractAddress, address youAddress); 
    error collectionNotFound(bool collectionFound, address collectionAddress);
    error promoCodeNotFound(bool promoFound);
    error incorrectIndex(bool promoFound,bytes8 promo);
    error incorrectCollectionAddress(address collectionAddress, address contractAddress);
    error incorrectNameLength(uint minimumNameLength, uint youNameLength);
    error onlyCollectionOwner(address creatorAddress, address youAddress);
    error incorrectAddress(bool zeroAddress);
    error Commission(uint minimumCommission, uint maximimCommission, uint youCommission);

}

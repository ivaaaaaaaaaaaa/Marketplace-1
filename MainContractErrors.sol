// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Errors {
    
    error NotEnoughFunds(uint price, uint getPrice);
    error PromoUsedAlredy(bool used);
    error InvalidPromo();
    error incorrectId();
    error ZeroCollectionAddress();
    error TokenNotExsist();
    error FailedToDeployContract();
    error notEnoughProductsInStock();
    error invalidPromoCode();
    error notEnoughFunds();
    error incorrectSymbolLength();
    error incorrectURI();
    error incorrectPrice();
    error incorrectQuantity();
    error onlyMainContract();
    error collectionNotFound();
    error promoCodeNotFound();
    error incorrectIndex();
    error incorrectCollectionAddress();
    error incorrectNameLength();
    error onlyCollectionOwner();
    error incorrectAddress();

}

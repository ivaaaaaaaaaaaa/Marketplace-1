import {ethers} from "hardhat";
import {expect} from "chai";

describe("Marketplace contract", function(){
  let owner:any;
  let user1:any;
  let marketplace:any;
  let tokenURI:any;

  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();
    const Marketplace = await ethers.getContractFactory("Marketpalce");
    marketplace = await Marketplace.deploy("MyNFT", "MTF");
    tokenURI = "https://example.com/metadata.json";
  })

  it("check deploy contract", async function () {
    expect(await marketplace.owner()).to.eq(owner.address);
    expect(await marketplace.tokenIds()).to.eq(1n);

    const contractAddress = await marketplace.target;
    expect(await marketplace.ownerOf(0)).to.eq(contractAddress);
    expect(await marketplace.balanceOf(contractAddress)).to.eq(1n);
  })  

  it("success create NFT and normal URI", async function () {
    const price = ethers.parseEther("0.1");
    const amount = ethers.parseEther("5");
    const contractBalanceBefore = await ethers.provider.getBalance(marketplace);
    const tokenId = await marketplace.tokenIds(); // 1
    
    await marketplace.createNFT(tokenURI, price, {value: amount});

    const URI = await marketplace.tokenURI(tokenId);
    console.log("Defoult URI: ",URI);
    
    const contractBalanceAfter = await ethers.provider.getBalance(marketplace);
    expect(await marketplace.balanceOf(owner.address)).to.eq(1n);
    expect(await marketplace.tokenIds()).to.eq(2n);
    expect(contractBalanceAfter).to.eq(contractBalanceBefore + price);
    expect(URI).to.eq(tokenURI);
  })

  it("success create zero URI", async function () {
    const price = ethers.parseEther("0.1");
    const amount = ethers.parseEther("5");
    const zeroURI = "";
    await marketplace.createNFT(zeroURI, price, {value: amount});
    const emptyURI = await marketplace.tokenURI(1);
    console.log("Empty URI: ",emptyURI);
  })

  it

})

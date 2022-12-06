const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toBigNum, fromBigNum } = require("./utils.js");

var exchangeRouter;
var exchangeFactory;
var wETH;
var token;
var nft;
var nftStaking;

var owner;
var user1;
var user2;
var user3;


var isOnchain = false; //true: testnet or main net, false: hardhat net

var deployedAddress = {
  exchangeFactory: "",
  wETH: "",
  exchangeRouter: "",
  token: "",
  nft: ""
};

describe("Create Account and wallet", () => {
  it("Create Wallet", async () => {
        [owner, user1, user2, user3, user4, user5, user6] = await ethers.getSigners();
        await checkETHBalance();
  });
});

describe("Contracts deploy", () => {
  // ------ dex deployment ------- //
  it("Factory deploy", async () => {
    const Factory = await ethers.getContractFactory("PancakeFactory");
    if (!isOnchain) {
      exchangeFactory = await Factory.deploy(owner.address);
      await exchangeFactory.deployed();
      // console.log(await exchangeFactory.INIT_CODE_PAIR_HASH());

    } else {
      exchangeFactory = Factory.attach(deployedAddress.exchangeFactory);
    }
    console.log("Factory", exchangeFactory.address);
  });

  it("wETH deploy", async () => {
    const WETH = await ethers.getContractFactory("WETH");
    if (!isOnchain) {
      wETH = await WETH.deploy();
      await wETH.deployed();
    } else {
      wETH = WETH.attach(deployedAddress.wETH);
    }
    console.log("WETH", wETH.address);
  });

  it("Router deploy", async () => {
    const Router = await ethers.getContractFactory("PancakeRouter");
    if (!isOnchain) {
      exchangeRouter = await Router.deploy(
        exchangeFactory.address,
        wETH.address
      );
      await exchangeRouter.deployed();
    } else {
      exchangeRouter = Router.attach(deployedAddress.exchangeRouter);
    }
    console.log("Router", exchangeRouter.address);
  });


  it("Token deploy", async () => {
    const Token = await ethers.getContractFactory("Token");
    if (!isOnchain) {
      token = await Token.deploy();
      await token.deployed();
    } else {
      token = Token.attach(deployedAddress.token);
    }
    console.log("Token", token.address);
  });


  it("NFT deploy", async () => {
    const NFT = await ethers.getContractFactory("BOBONFT");
    if (!isOnchain) {
      nft = await NFT.deploy();
      await nft.deployed();
    } else {
      nft = NFT.attach(deployedAddress.nft);
    }
    console.log("NFT", nft.address);
  });

  it("NFTSTAKING deploy", async () => {
    const NFTSTAKING = await ethers.getContractFactory("NFTStaking");
    if (!isOnchain) {
      nftStaking = await NFTSTAKING.deploy(nft.address, token.address);
      await nftStaking.deployed();
    } else {
      nftStaking = NFTSTAKING.attach(deployedAddress.nftStaking);
    }
    console.log("NFTSTAKING", nftStaking.address);
  });

});


describe("test", () => {
  it("creat pool", async () => {
    if (!isOnchain) {
      var tx = await token.approve(
        exchangeRouter.address,
        toBigNum("10000")
      );
      await tx.wait();

      var tx = await exchangeRouter.addLiquidityETH(
        token.address,
        toBigNum("10000"),
        0,
        0,
        owner.address,
        "1234325432314321",
        { value: toBigNum("0.0001") }
      );
      await tx.wait();
    }
  });

  it("users mint NFTs", async () => {
    if (!isOnchain) {
      var tx = await nft.connect(user1).mint(1, {value: toBigNum("0.00001")});
      await tx.wait();
      var tx = await nft.connect(user2).mint(2, {value: toBigNum("0.00002")});
      await tx.wait();
      var tx = await nft.connect(user3).mint(3, {value: toBigNum("0.00003")});
      await tx.wait();
      await checkNFTBalance();
    }
  });

  it("user1 stake 1 NFT, user2 stake 2 NFTs, user3 stake 3 NFTs", async () => {
    if (!isOnchain) {
      var tx = await nft.connect(user1).approve(nftStaking.address, 1);
      await tx.wait();
      var tx = await nftStaking.connect(user1).stake(1);
      await tx.wait();

      var tx = await nft.connect(user2).approve(nftStaking.address, 2);
      await tx.wait();
      var tx = await nft.connect(user2).approve(nftStaking.address, 3);
      await tx.wait();
      var tx = await nftStaking.connect(user2).stakeBatch([2, 3]);
      await tx.wait();

      var tx = await nft.connect(user3).approve(nftStaking.address, 4);
      await tx.wait();
      var tx = await nft.connect(user3).approve(nftStaking.address, 5);
      await tx.wait();
      var tx = await nft.connect(user3).approve(nftStaking.address, 6);
      await tx.wait();
      var tx = await nftStaking.connect(user3).stakeBatch([4, 5, 6]);
      await tx.wait();

      await checkNFTBalance();
    }
  });

  it("owner deposit 600 tokens for reward", async () => {
    if (!isOnchain) {
      var tx = await token.approve(nftStaking.address, toBigNum("600"));
      await tx.wait();
      var tx = await nftStaking.depositRewardToken(toBigNum("600"));
      await tx.wait();
    }
  });

  it("check pending token rewards", async () => {
    if (!isOnchain) {
      var user1PendingToken = await nftStaking.getPendingToken(user1.address);
      console.log("user1 pending token", fromBigNum(user1PendingToken));

      var user2PendingToken = await nftStaking.getPendingToken(user2.address);
      console.log("user2 pending token", fromBigNum(user2PendingToken));

      var user3PendingToken = await nftStaking.getPendingToken(user3.address);
      console.log("user3 pending token", fromBigNum(user3PendingToken));
    }
  });

  it("owner deposit 6 eth for reward", async () => {
    if (!isOnchain) {
      var tx = await nftStaking.depositRewardEth({value: toBigNum("6")});
      await tx.wait();
    }
  });

  it("check pending eth rewards", async () => {
    if (!isOnchain) {
      var user1PendingETH = await nftStaking.getPendingEth(user1.address);
      console.log("user1 pending eth", fromBigNum(user1PendingETH));

      var user2PendingETH = await nftStaking.getPendingEth(user2.address);
      console.log("user2 pending eth", fromBigNum(user2PendingETH));

      var user3PendingETH = await nftStaking.getPendingEth(user3.address);
      console.log("user3 pending eth", fromBigNum(user3PendingETH));
    }
  });

  it("check balances before claim", async () => {
    if (!isOnchain) {
      await checkETHBalance();
      await checkTokenBalance();
    }
  });

  it("claim rewards", async () => {
    if (!isOnchain) {
      var tx = await nftStaking.connect(user1).claimRewards();
      await tx.wait();

      var tx = await nftStaking.connect(user2).claimRewards();
      await tx.wait();

      var tx = await nftStaking.connect(user3).claimRewards();
      await tx.wait();
    }
  });

  it("check balances after claim", async () => {
    if (!isOnchain) {
      await checkETHBalance();
      await checkTokenBalance();
    }
  });

  it("user1 unstake 1 NFT, user2 unstake 2 NFTs", async () => {
    var tx = await nftStaking.connect(user1).unstake(1);
    await tx.wait();

    var tx = await nftStaking.connect(user2).unstakeBatch([2, 3]);
    await tx.wait();
    
    await checkNFTBalance();
  })


  it("check user3 staked NFT ID", async () => {
    var tokenIds = await nftStaking.getStakedTokens(user3.address);
    console.log("user3 staked NFT IDs", tokenIds);

  })


})


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

const checkETHBalance = async () =>{
  console.log("owner ETH balance", fromBigNum(await ethers.provider.getBalance(owner.address)));
  console.log("user1 ETH balance", fromBigNum(await ethers.provider.getBalance(user1.address)));
  console.log("user2 ETH balance", fromBigNum(await ethers.provider.getBalance(user2.address)));
  console.log("user3 ETH balance", fromBigNum(await ethers.provider.getBalance(user3.address)));
}

const checkTokenBalance = async () =>{
  console.log("owner TOKEN balance", fromBigNum(await token.balanceOf(user1.address)));
  console.log("user1 TOKEN balance", fromBigNum(await token.balanceOf(user2.address)));
  console.log("user2 TOKEN balance", fromBigNum(await token.balanceOf(user3.address)));
  console.log("user3 TOKEN balance", fromBigNum(await token.balanceOf(user4.address)));
}

const checkNFTBalance = async () =>{
  console.log("user1 NFT balance", fromBigNum(await nft.balanceOf(user1.address), 0));
  console.log("user2 NFT balance", fromBigNum(await nft.balanceOf(user2.address), 0));
  console.log("user3 NFT balance", fromBigNum(await nft.balanceOf(user3.address), 0));

}

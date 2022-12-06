//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract NFTStaking is Ownable{

    struct Staker {
        uint256[] tokenIds;
        mapping (uint256 => uint256) tokenIndex;
        uint256 stakedNum;
        uint256 tokenMask;
        uint256 pendingToken;
        uint256 claimedToken;
        uint256 ethMask;
        uint256 pendingEth;
        uint256 claimedEth;
    }

    IERC721A public boboNFT;
    IERC20 public rewardToken;

    uint256 private tokenRoundMask;
    uint256 private ethRoundMask;

    uint256 public totalStakedNum;
    uint256 public totalTokenClaimed;
    uint256 public totalEthClaimed;

    mapping(address => Staker) public stakers;

    // Mapping: token ID => owner address
    mapping (uint256 => address) public tokenOwner;

    event Stake(address indexed _staker, uint256 _tokenId);
    event Unstake(address indexed _staker, uint256 _tokenId);
    event ClaimRewards(address indexed _staker, uint256 _tokenAmount, uint256 _ethAmount);


    constructor(
        address nftAddress,
        address tokenAddress
    ) {
        boboNFT = IERC721A(nftAddress);
        rewardToken = IERC20(tokenAddress);
    }


    function stake(uint256 tokenId) external {
        _stake(msg.sender, tokenId);
    }


    function stakeBatch(uint256[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
    }


    function _stake(
        address _staker,
        uint256 _tokenId
    )
        internal
    {
        Staker storage staker = stakers[_staker];

        updateRewardMasks();

        staker.tokenIds.push(_tokenId);
        staker.tokenIndex[_tokenId] = staker.tokenIds.length - 1;
        tokenOwner[_tokenId] = _staker;

        boboNFT.transferFrom(
            _staker,
            address(this),
            _tokenId
        );
        totalStakedNum += 1;
        staker.stakedNum += 1;

        emit Stake(_staker, _tokenId);
    }


    function unstake(uint256 _tokenId) external {
        require(tokenOwner[_tokenId] == msg.sender, "Sender must have staked tokenID");
        claimRewards();
        _unstake(msg.sender, _tokenId);
    }


    function unstakeBatch(uint256[] memory tokenIds) external {
        claimRewards();
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }


    function _unstake(
        address _user,
        uint256 _tokenId
    ) 
        internal 
    {
        Staker storage staker = stakers[_user];

        totalStakedNum -= 1;
        staker.stakedNum -= 1;

        uint256 lastTokenId = staker.tokenIds[staker.tokenIds.length - 1];
        uint256 tokenIdIndex = staker.tokenIndex[_tokenId];
        
        staker.tokenIds[tokenIdIndex] = lastTokenId;
        staker.tokenIndex[lastTokenId] = tokenIdIndex;
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
            delete staker.tokenIndex[_tokenId];
        }

        if (staker.stakedNum == 0) {
            delete stakers[_user];
        }
        delete tokenOwner[_tokenId];

        boboNFT.transferFrom(
            address(this),
            _user,
            _tokenId
        );

        emit Unstake(msg.sender, _tokenId);
    }


    function claimRewards() public {

        updateRewardMasks();

        uint256 pendingToken = stakers[msg.sender].pendingToken;
        uint256 pendingEth = stakers[msg.sender].pendingEth;

        stakers[msg.sender].pendingToken = 0;
        stakers[msg.sender].claimedToken += pendingToken;
        stakers[msg.sender].pendingEth = 0;
        stakers[msg.sender].claimedEth += pendingEth;

        rewardToken.transfer(msg.sender, pendingToken);
        _transferEth(msg.sender, pendingEth);

        totalTokenClaimed += pendingToken;
        totalEthClaimed += pendingEth;

        emit ClaimRewards(msg.sender, pendingToken, pendingEth);
    }


    function updateRewardMasks() public {

        uint256 pendingToken = getPendingToken(msg.sender);
        stakers[msg.sender].pendingToken = pendingToken;
        stakers[msg.sender].tokenMask = tokenRoundMask;

        uint256 pendingEth = getPendingEth(msg.sender);
        stakers[msg.sender].pendingEth = pendingEth;
        stakers[msg.sender].ethMask = ethRoundMask;
    }


    function getPendingToken(address staker)
        public
        view
        returns (uint256)
    {
        if (stakers[staker].stakedNum == 0) return 0;
        return
            stakers[staker].pendingToken +
            (tokenRoundMask - stakers[staker].tokenMask) * stakers[staker].stakedNum;
    }

        
    function getPendingEth(address staker)
        public
        view
        returns (uint256)
    {
        if (stakers[staker].stakedNum == 0) return 0;
        return
            stakers[staker].pendingEth +
            (ethRoundMask - stakers[staker].ethMask) * stakers[staker].stakedNum;
    }


    function getStakedTokens(address staker)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[staker].tokenIds;
    }


    function depositRewardToken(uint256 amount)
        external
        onlyOwner
    {
        require(totalStakedNum > 0, "totalStakedNum amount is 0");
        rewardToken.transferFrom(msg.sender, address(this), amount);
        tokenRoundMask += amount / totalStakedNum;
    }


    function depositRewardEth()
        external
        payable
        onlyOwner
    {
        require(totalStakedNum > 0, "totalStakedNum amount is 0");
        _transferEth(address(this), msg.value);
        ethRoundMask += msg.value / totalStakedNum;
    }

    function setRewardToken(address tokenAddress) external onlyOwner {
        rewardToken = IERC20(tokenAddress);
    }

    function setNFT(address nftAddress) external onlyOwner {
        boboNFT = IERC721A(nftAddress);
    }


    /// @notice payout function
    /// @dev care about non reentrant vulnerabilities
    function _transferEth(address to, uint256 amount) internal {
        (bool transferSuccess, ) = payable(to).call{ value: amount } ("");
        require(transferSuccess, "eth transfer failed");
    }

    receive() external payable { }

}
// Froggy Friends by Fonzy & Mayan (www.froggyfriendsnft.com) $RIBBIT token

//...................................................@@@@@........................
//.......................%@@@@@@@@@*.............@@@@#///(@@@@@...................
//....................@@@&(//(//(/(@@@.........&@@////////////@@@.................
//....................@@@//////////////@@@@@@@@@@@@/////@@@@/////@@@..............
//..................%@@/////@@@@@(////////////////////%@@@@/////#@@...............
//..................@@%//////@@@#///////////////////////////////@@@...............
//..................@@@/////////////////////////////////////////@@@@..............
//..................@@(///////////////(///////////////(////////////@@@............
//...............*@@/(///////////////&@@@@@@(//(@@@@@@/////////////#@@............
//...............@@////////////////////////(%&&%(///////////////////@@@...........
//..............@@@/////////////////////////////////////////////////&@@...........
//..............@@(/////////////////////////////////////////////////@@#...........
//..............@@@////////////////////////////////////////////////@@@............
//...............@@@/////////////////////////////////////////////#@@/.............
//................&@@@//////////////////////////////////////////@@@...............
//..................*@@@%////////////////////////////////////@@@@.................
//...............@@@@///////////////////////////////////////(@@@..................
//............%@@@////////////////............/////////////////@@@................
//..........%@@#/////////////..................... (/////////////@@@..............
//.........@@@////////////............................////////////@@@.............
//........@@(///////(@@@................................(@@&///////&@@............
//.......@@////////@@@....................................@@@///////@@@...........
//......@@@///////@@@.......................................@@///////@@%..........
//.....(@@///////@@@.........................................@@/////(/@@..........

// Development help from Lexi

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IFroggyFriends {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IRibbit {
    function mint(address add, uint256 amount) external;
}

interface Ierc20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IRibbitItem {
    function burn(address from, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isBoost(uint256 id) external view returns (bool);
    function boostPercentage(uint256 id) external view returns (uint256);
}

contract StakeFroggies is IERC721Receiver, Ownable {
    using Strings for uint256;
    IFroggyFriends froggyFriends;
    IRibbit ribbit;
    Ierc20 ierc20;
    IRibbitItem ribbitItem;
    bool public started = true;
    bytes32 public root = 0x339f267449a852acfbd5c472061a8fc4941769c9a3a9784778e7e95f9bb8f18d;
    uint256[] public rewardTiers = [20, 30, 40, 75, 150];
    mapping(uint256 => mapping(address => uint256)) private idToStartingTime;
    mapping(address => uint256[]) froggiesStaked;
    mapping(uint256 => uint256) idTokenRate;
    mapping(uint256 => address) idToStaker;
    mapping(uint256 => bool) boosted;
    mapping(uint256 => uint256) defaultRate;
    mapping(uint256 => uint256) idTokenRateBoosted;

    constructor(address _froggyFriends) {
        froggyFriends = IFroggyFriends(_froggyFriends);
    }

    function isValid(bytes32[] memory proof, string memory numstr) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(numstr));
        return MerkleProof.verify(proof, root, leaf);
    }

    function getTokenRewardRate(uint256 tokenId, bytes32[] memory proof) public view returns (uint256) {
        for (uint256 i; i < rewardTiers.length; i++) {
            string memory numstring = string(abi.encodePacked(tokenId.toString(), rewardTiers[i].toString()));

            if (isValid(proof, numstring) == true) {
                return rewardTiers[i];
            }
        }
        return 0;
    }

    function stake(uint256[] memory tokenIds, bytes32[][] memory proof) external {
        require(started == true, "$RIBBIT staking paused");
        uint256[] memory _tokenIds = new uint256[](tokenIds.length);
        _tokenIds = tokenIds;
        for (uint256 i; i < _tokenIds.length; i++) {
            require(froggyFriends.ownerOf(_tokenIds[i]) == msg.sender, "Not your Froggy Friend");
            idToStartingTime[_tokenIds[i]][msg.sender] = block.timestamp;
            froggyFriends.transferFrom(msg.sender, address(this), _tokenIds[i]);
            idToStaker[_tokenIds[i]] = msg.sender;
            idTokenRate[_tokenIds[i]] = getTokenRewardRate(_tokenIds[i], proof[i]);
            froggiesStaked[msg.sender].push(_tokenIds[i]);
        }
    }

    function unStake(uint256[] memory tokenIds) external {
        uint256[] memory _tokenIds = new uint256[](tokenIds.length);
        _tokenIds = tokenIds;
        for (uint256 i; i < _tokenIds.length; i++) {
            require(idToStaker[_tokenIds[i]] == msg.sender, "Not your Froggy Friend");
            froggyFriends.transferFrom(address(this), msg.sender, _tokenIds[i]);
            for (uint256 j; j < froggiesStaked[msg.sender].length; j++) {
                if (froggiesStaked[msg.sender][j] == _tokenIds[i]) {
                    froggiesStaked[msg.sender][j] = froggiesStaked[msg.sender][froggiesStaked[msg.sender].length - 1];
                    froggiesStaked[msg.sender].pop();
                    break;
                }
            }

            uint256 current;
            uint256 reward;
            delete idToStaker[_tokenIds[i]];
            if (idToStartingTime[_tokenIds[i]][msg.sender] > 0) {
                if (boosted[_tokenIds[i]] == false) {
                    uint256 rate = idTokenRate[_tokenIds[i]];
                    current = block.timestamp - idToStartingTime[_tokenIds[i]][msg.sender];
                    reward = ((rate * 10**18) * current) / 86400;
                    ribbit.mint(msg.sender, reward);
                    idToStartingTime[_tokenIds[i]][msg.sender] = 0;
                }

                if (boosted[_tokenIds[i]] == true) {
                    uint256 rate = idTokenRateBoosted[_tokenIds[i]];
                    current = block.timestamp - idToStartingTime[_tokenIds[i]][msg.sender];
                    reward = (((rate * 10**18) / 1000) * current) / 86400;
                    ribbit.mint(msg.sender, reward);
                    idToStartingTime[_tokenIds[i]][msg.sender] = 0;
                }
            }
        }
    }

    function setRewardTierAndRoot(uint256[] memory _rewardTiers, bytes32 _root) public onlyOwner {
        rewardTiers = _rewardTiers;
        root = _root;
    }

    function setStakingState(bool _state) public onlyOwner {
        started = _state;
    }

    function setRibbitAddress(address add) public onlyOwner {
        ribbit = IRibbit(add);
    }

    function setRibbitItemContract(address add) public onlyOwner {
        ribbitItem = IRibbitItem(add);
    }

    function pairFriend(uint256 tokenId, bytes32[] memory proof, uint256 friend) public {
        require(ribbitItem.balanceOf(msg.sender, friend) > 0, "Friend not owned");
        require(ribbitItem.isBoost(friend) == true, "$RIBBIT item is not a Friend");
        require(boosted[tokenId] == false, "Friend already paired");
        require(froggyFriends.ownerOf(tokenId) == msg.sender, "Not your Froggy Friend");
        boosted[tokenId] = true;
        uint256 rate = getTokenRewardRate(tokenId, proof);
        defaultRate[tokenId] = rate;
        idTokenRateBoosted[tokenId] = rate * 1000 + (ribbitItem.boostPercentage(friend) * rate * 1000) / 100;
        ribbitItem.burn(msg.sender, friend, 1);
    }

    function unpairFriend(uint256 froggyId) public {
        require(boosted[froggyId] == true, "Friend is not paired");
        require(froggyFriends.ownerOf(froggyId) == msg.sender, "Not your Froggy Friend");
        boosted[froggyId] = false;
        idTokenRateBoosted[froggyId] = 0;
        idTokenRate[froggyId] = defaultRate[froggyId];
    }

    function claimreward() public {
        require(froggiesStaked[msg.sender].length > 0, "No froggies staked");
        uint256[] memory tokenIds = new uint256[](
            froggiesStaked[msg.sender].length
        );
        tokenIds = froggiesStaked[msg.sender];

        uint256 current;
        uint256 reward;
        uint256 rewardbal;
        for (uint256 i; i < tokenIds.length; i++) {
            if (idToStartingTime[tokenIds[i]][msg.sender] > 0) {
                if (boosted[tokenIds[i]] == false) {
                    uint256 rate = idTokenRate[tokenIds[i]];
                    current =
                        block.timestamp -
                        idToStartingTime[tokenIds[i]][msg.sender];
                    reward = ((rate * 10**18) * current) / 86400;
                    rewardbal += reward;
                    idToStartingTime[tokenIds[i]][msg.sender] = block
                        .timestamp;
                }

                if (boosted[tokenIds[i]] == true) {
                    uint256 rate = idTokenRateBoosted[tokenIds[i]];
                    current =
                        block.timestamp -
                        idToStartingTime[tokenIds[i]][msg.sender];
                    reward = (((rate * 10**18) / 1000) * current) / 86400;
                    rewardbal += reward;
                    idToStartingTime[tokenIds[i]][msg.sender] = block
                        .timestamp;
                }
            }
        }

        ribbit.mint(msg.sender, rewardbal);
    }

    function checkrewardbal(uint256 tokenId) public view returns (uint256) {
        uint256 current;
        uint256 reward;

        if (idToStartingTime[tokenId][msg.sender] > 0) {
            if (boosted[tokenId] == false) {
                uint256 rate = idTokenRate[tokenId];
                current =
                    block.timestamp -
                    idToStartingTime[tokenId][msg.sender];
                reward = ((rate * 10**18) * current) / 86400;
            }

            if (boosted[tokenId] == true) {
                uint256 rate = idTokenRateBoosted[tokenId];
                current =
                    block.timestamp -
                    idToStartingTime[tokenId][msg.sender];
                reward = (((rate * 10**18) / 1000) * current) / 86400;
            }

            return reward;
        }
    }

    function checkrewardbalforall(address account) public view returns (uint256) {
        uint256[] memory tokenIds = new uint256[](
            froggiesStaked[account].length
        );
        tokenIds = froggiesStaked[account];

        uint256 current;
        uint256 reward;
        uint256 rewardbal;
        for (uint256 i; i < tokenIds.length; i++) {
            if (idToStartingTime[tokenIds[i]][account] > 0) {
                if (boosted[tokenIds[i]] == false) {
                    uint256 rate = idTokenRate[tokenIds[i]];
                    current =
                        block.timestamp -
                        idToStartingTime[tokenIds[i]][account];
                    reward = ((rate * 10**18) * current) / 86400;
                    rewardbal += reward;
                }

                if (boosted[tokenIds[i]] == true) {
                    uint256 rate = idTokenRateBoosted[tokenIds[i]];
                    current =
                        block.timestamp -
                        idToStartingTime[tokenIds[i]][account];
                    reward = (((rate * 10**18) / 1000) * current) / 86400;
                    rewardbal += reward;
                }
            }
        }
        return rewardbal;
    }

    function getFroggiesStaked(address account) public view returns (uint256[] memory) {
        return froggiesStaked[account];
    }

    function withdrawerc20(address erc20addd, address _to) public onlyOwner {
        ierc20 = Ierc20(erc20addd);
        ierc20.transfer(_to, ierc20.balanceOf(address(this)));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

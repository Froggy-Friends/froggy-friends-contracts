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

interface IERC20 {
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
    address public froggyAddress;
    address public ribbitAddress;
    IFroggyFriends _froggyFriends;
    IRibbit _ribbit;
    IERC20 _erc20interface;
    IRibbitItem _ribbitItem;
    bool public started = true;
    bytes32 public root = 0x339f267449a852acfbd5c472061a8fc4941769c9a3a9784778e7e95f9bb8f18d;
    uint256[] public rewardtier = [20, 30, 40, 75, 150];
    mapping(uint256 => mapping(address => uint256)) private idToStartingTime;
    mapping(address => uint256[]) froggiesStaked;
    mapping(uint256 => uint256) idTokenRate;
    mapping(uint256 => address) idToStaker;
    mapping(uint256 => bool) boosted;
    mapping(uint256 => uint256) defaultRate;
    mapping(uint256 => uint256) idTokenRateBoosted;

    constructor(address _froggyAddress) {
        _froggyFriends = IFroggyFriends(_froggyAddress);
    }

    function isValid(bytes32[] memory proof, string memory numstr)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(numstr));
        return MerkleProof.verify(proof, root, leaf);
    }

    function setribbitAddress(address add) public onlyOwner {
        _ribbit = IRibbit(add);
    }

    function setrewardtierandroot(uint256[] memory settier, bytes32 _root)
        public
        onlyOwner
    {
        rewardtier = settier;
        root = _root;
    }

    function geTokenrewardrate(uint256 tokenId, bytes32[] memory proof)
        public
        view
        returns (uint256)
    {
        for (uint256 i; i < rewardtier.length; i++) {
            string memory numstring = string(
                abi.encodePacked(tokenId.toString(), rewardtier[i].toString())
            );

            if (isValid(proof, numstring) == true) {
                return rewardtier[i];
            }
        }
        return 0;
    }

    function setstakingstate(bool _state) public onlyOwner {
        started = _state;
    }

    function stake(uint256[] memory tokenIds, bytes32[][] memory proof)
        external
    {
        require(started == true, "staking is paused");
        uint256[] memory _tokenIds = new uint256[](tokenIds.length);
        _tokenIds = tokenIds;
        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                _froggyFriends.ownerOf(_tokenIds[i]) == msg.sender,
                "not your froggynft"
            );
            idToStartingTime[_tokenIds[i]][msg.sender] = block.timestamp;
            _froggyFriends.transferFrom(msg.sender, address(this), _tokenIds[i]);
            idToStaker[_tokenIds[i]] = msg.sender;
            idTokenRate[_tokenIds[i]] = geTokenrewardrate(
                _tokenIds[i],
                proof[i]
            );
            froggiesStaked[msg.sender].push(_tokenIds[i]);
        }
    }

    function unstake(uint256[] memory tokenIds) external {
        uint256[] memory _tokenIds = new uint256[](tokenIds.length);
        _tokenIds = tokenIds;
        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                idToStaker[_tokenIds[i]] == msg.sender,
                "you are not the staker"
            );
            _froggyFriends.transferFrom(address(this), msg.sender, _tokenIds[i]);
            for (uint256 j; j < froggiesStaked[msg.sender].length; j++) {
                if (froggiesStaked[msg.sender][j] == _tokenIds[i]) {
                    froggiesStaked[msg.sender][
                        j
                    ] = froggiesStaked[msg.sender][
                        froggiesStaked[msg.sender].length - 1
                    ];
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
                    current =
                        block.timestamp -
                        idToStartingTime[_tokenIds[i]][msg.sender];
                    reward = ((rate * 10**18) * current) / 86400;
                    _ribbit.mint(msg.sender, reward);
                    idToStartingTime[_tokenIds[i]][msg.sender] = 0;
                }

                if (boosted[_tokenIds[i]] == true) {
                    uint256 rate = idTokenRateBoosted[_tokenIds[i]];
                    current =
                        block.timestamp -
                        idToStartingTime[_tokenIds[i]][msg.sender];
                    reward = (((rate * 10**18) / 1000) * current) / 86400;
                    _ribbit.mint(msg.sender, reward);
                    idToStartingTime[_tokenIds[i]][msg.sender] = 0;
                }
            }
        }
    }

    function setboostercontract(address add) public onlyOwner {
        _ribbitItem = IRibbitItem(add);
    }

    function boostrate(
        uint256 tokenIds,
        bytes32[] memory proof,
        uint256 boostingid
    ) public {
        require(
            _ribbitItem.balanceOf(msg.sender, boostingid) > 0,
            "you dont have an erc1155 item"
        );
        require(
            _ribbitItem.isBoost(boostingid) == true,
            "not a boosting item"
        );
        require(
            boosted[tokenIds] == false,
            "already boosted,please unboost before applying new boost"
        );
        require(
            _froggyFriends.ownerOf(tokenIds) == msg.sender,
            "not your froggynft ,you cant apply boost"
        );
        boosted[tokenIds] = true;
        uint256 _idtokenrate = geTokenrewardrate(tokenIds, proof);
        defaultRate[tokenIds] = _idtokenrate;
        idTokenRateBoosted[tokenIds] =
            _idtokenrate *
            1000 +
            (_ribbitItem.boostPercentage(boostingid) *
                _idtokenrate *
                1000) /
            100;
        _ribbitItem.burn(msg.sender, boostingid, 1);
    }

    function unboostrate(uint256 tokenIds) public {
        require(
            boosted[tokenIds] == true,
            "you have not boosted,please boost before applying  unboost"
        );
        require(
            _froggyFriends.ownerOf(tokenIds) == msg.sender,
            "not your froggynft ,you cant apply unboost"
        );
        boosted[tokenIds] = false;
        idTokenRateBoosted[tokenIds] = 0;
        idTokenRate[tokenIds] = defaultRate[tokenIds];
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

        _ribbit.mint(msg.sender, rewardbal);
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
        _erc20interface = IERC20(erc20addd);
        _erc20interface.transfer(_to, _erc20interface.balanceOf(address(this)));
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

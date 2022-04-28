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
    function checkifboostid(uint256 id) external view returns (bool);
    function checkpercentage(uint256 id) external view returns (uint256);
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
    mapping(uint256 => mapping(address => uint256)) private idtostartingtimet;
    mapping(address => uint256[]) allnftstakeforaddress;
    mapping(uint256 => uint256) idtokenrate;
    mapping(uint256 => address) idtostaker;
    mapping(uint256 => bool) boosted;
    mapping(uint256 => uint256) previousratebeforeboost;
    mapping(uint256 => uint256) idtokenratewhenboosted;

    // for test
    uint256 public check;
    uint256 public check2;

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
        bool check;
        for (uint256 i; i < rewardtier.length; i++) {
            string memory numstring = string(
                abi.encodePacked(tokenId.toString(), rewardtier[i].toString())
            );

            if (isValid(proof, numstring) == true) {
                check = true;
                return rewardtier[i];
            }
        }
        require(check == true, "invalid parameters");
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
            idtostartingtimet[_tokenIds[i]][msg.sender] = block.timestamp;
            _froggyFriends.transferFrom(msg.sender, address(this), _tokenIds[i]);
            idtostaker[_tokenIds[i]] = msg.sender;
            idtokenrate[_tokenIds[i]] = geTokenrewardrate(
                _tokenIds[i],
                proof[i]
            );
            allnftstakeforaddress[msg.sender].push(_tokenIds[i]);
        }
    }

    function unstake(uint256[] memory tokenIds) external {
        uint256[] memory _tokenIds = new uint256[](tokenIds.length);
        _tokenIds = tokenIds;
        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                idtostaker[_tokenIds[i]] == msg.sender,
                "you are not the staker"
            );
            _froggyFriends.transferFrom(address(this), msg.sender, _tokenIds[i]);
            for (uint256 j; j < allnftstakeforaddress[msg.sender].length; j++) {
                if (allnftstakeforaddress[msg.sender][j] == _tokenIds[i]) {
                    allnftstakeforaddress[msg.sender][
                        j
                    ] = allnftstakeforaddress[msg.sender][
                        allnftstakeforaddress[msg.sender].length - 1
                    ];
                    allnftstakeforaddress[msg.sender].pop();
                    break;
                }
            }

            uint256 current;
            uint256 reward;
            delete idtostaker[_tokenIds[i]];
            if (idtostartingtimet[_tokenIds[i]][msg.sender] > 0) {
                if (boosted[_tokenIds[i]] == false) {
                    uint256 rate = idtokenrate[_tokenIds[i]];
                    current =
                        block.timestamp -
                        idtostartingtimet[_tokenIds[i]][msg.sender];
                    reward = ((rate * 10**18) * current) / 86400;
                    _ribbit.mint(msg.sender, reward);
                    idtostartingtimet[_tokenIds[i]][msg.sender] = 0;
                }

                if (boosted[_tokenIds[i]] == true) {
                    uint256 rate = idtokenratewhenboosted[_tokenIds[i]];
                    current =
                        block.timestamp -
                        idtostartingtimet[_tokenIds[i]][msg.sender];
                    reward = (((rate * 10**18) / 1000) * current) / 86400;
                    _ribbit.mint(msg.sender, reward);
                    idtostartingtimet[_tokenIds[i]][msg.sender] = 0;
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
            _ribbitItem.checkifboostid(boostingid) == true,
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
        previousratebeforeboost[tokenIds] = _idtokenrate;
        check2 = idtokenrate[tokenIds];
        idtokenratewhenboosted[tokenIds] =
            _idtokenrate *
            1000 +
            (_ribbitItem.checkpercentage(boostingid) *
                _idtokenrate *
                1000) /
            100;
        // uint d= idtokenrate[tokenIds]*1000 + (5*idtokenrate[tokenIds]*1000)/100;
        check = idtokenratewhenboosted[tokenIds];
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
        idtokenratewhenboosted[tokenIds] = 0;
        idtokenrate[tokenIds] = previousratebeforeboost[tokenIds];
    }

    function claimreward() public {
        uint256[] memory tokenIds = new uint256[](
            allnftstakeforaddress[msg.sender].length
        );
        tokenIds = allnftstakeforaddress[msg.sender];

        uint256 current;
        uint256 reward;
        uint256 rewardbal;
        for (uint256 i; i < tokenIds.length; i++) {
            if (idtostartingtimet[tokenIds[i]][msg.sender] > 0) {
                if (boosted[tokenIds[i]] == false) {
                    uint256 rate = idtokenrate[tokenIds[i]];
                    current =
                        block.timestamp -
                        idtostartingtimet[tokenIds[i]][msg.sender];
                    reward = ((rate * 10**18) * current) / 86400;
                    rewardbal += reward;
                    idtostartingtimet[tokenIds[i]][msg.sender] = block
                        .timestamp;
                }

                if (boosted[tokenIds[i]] == true) {
                    uint256 rate = idtokenratewhenboosted[tokenIds[i]];
                    current =
                        block.timestamp -
                        idtostartingtimet[tokenIds[i]][msg.sender];
                    reward = (((rate * 10**18) / 1000) * current) / 86400;
                    rewardbal += reward;
                    idtostartingtimet[tokenIds[i]][msg.sender] = block
                        .timestamp;
                }
            }
        }

        _ribbit.mint(msg.sender, rewardbal);
    }

    function checkrewardbal(uint256 tokenId) public view returns (uint256) {
        uint256 current;
        uint256 reward;

        if (idtostartingtimet[tokenId][msg.sender] > 0) {
            if (boosted[tokenId] == false) {
                uint256 rate = idtokenrate[tokenId];
                current =
                    block.timestamp -
                    idtostartingtimet[tokenId][msg.sender];
                reward = ((rate * 10**18) * current) / 86400;
            }

            if (boosted[tokenId] == true) {
                uint256 rate = idtokenratewhenboosted[tokenId];
                current =
                    block.timestamp -
                    idtostartingtimet[tokenId][msg.sender];
                reward = (((rate * 10**18) / 1000) * current) / 86400;
            }

            return reward;
        }
    }

    function checkrewardbalforall() public view returns (uint256) {
        uint256[] memory tokenIds = new uint256[](
            allnftstakeforaddress[msg.sender].length
        );
        tokenIds = allnftstakeforaddress[msg.sender];

        uint256 current;
        uint256 reward;
        uint256 rewardbal;
        for (uint256 i; i < tokenIds.length; i++) {
            if (idtostartingtimet[tokenIds[i]][msg.sender] > 0) {
                if (boosted[tokenIds[i]] == false) {
                    uint256 rate = idtokenrate[tokenIds[i]];
                    current =
                        block.timestamp -
                        idtostartingtimet[tokenIds[i]][msg.sender];
                    reward = ((rate * 10**18) * current) / 86400;
                    rewardbal += reward;
                }

                if (boosted[tokenIds[i]] == true) {
                    uint256 rate = idtokenratewhenboosted[tokenIds[i]];
                    current =
                        block.timestamp -
                        idtostartingtimet[tokenIds[i]][msg.sender];
                    reward = (((rate * 10**18) / 1000) * current) / 86400;
                    rewardbal += reward;
                }
                //   idtostartingtimet[tokenIds[i]][msg.sender]=block.timestamp;
            }
        }
        return rewardbal;
    }

    function checkallnftstaked() public view returns (uint256[] memory) {
        return allnftstakeforaddress[msg.sender];
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

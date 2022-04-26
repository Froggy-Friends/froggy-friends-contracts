pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface Ifroggynft {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ribbit {
    function mint(address add, uint256 amount) external;
}

interface erc20interface {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract StakeFroggies is IERC721Receiver, Ownable {
    using Strings for uint256;
    address public froggyAddress;
    address public ribbitAddress;
    Ifroggynft _froggynft;
    ribbit _ribbit;
    erc20interface _erc20interface;
    bool public started = true;
    bytes32 public root = 0x339f267449a852acfbd5c472061a8fc4941769c9a3a9784778e7e95f9bb8f18d;
    uint256[] public rewardtier = [20, 30, 40, 75, 150];
    mapping(uint256 => mapping(address => uint256)) private idtostartingtimet;
    mapping(address => uint256[]) allnftstakeforaddress;
    mapping(uint256 => uint256) idtokenrate;
    mapping(uint256 => address) idtostaker;

    constructor(address _froggyAddress) {
        _froggynft = Ifroggynft(_froggyAddress);
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
        _ribbit = ribbit(add);
    }

    function setrewardtier(uint256[] memory settier) public onlyOwner {
        rewardtier = settier;
    }

    function setroot(bytes32 _root) public onlyOwner {
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
    }

    function setstakingstate() public onlyOwner {
        started = !started;
    }

    function stake(uint256[] memory tokenIds, bytes32[][] memory proof)
        external
    {
        require(started == true, "staking is paused");
        uint256[] memory _tokenIds = new uint256[](tokenIds.length);
        _tokenIds = tokenIds;
        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                _froggynft.ownerOf(_tokenIds[i]) == msg.sender,
                "not your froggynft"
            );
            idtostartingtimet[_tokenIds[i]][msg.sender] = block.timestamp;
            _froggynft.transferFrom(msg.sender, address(this), _tokenIds[i]);
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
            _froggynft.transferFrom(address(this), msg.sender, _tokenIds[i]);
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
                uint256 rate = idtokenrate[_tokenIds[i]];
                current =
                    block.timestamp -
                    idtostartingtimet[_tokenIds[i]][msg.sender];
                reward = ((rate * 10**18) * current) / 86400;
                _ribbit.mint(msg.sender, reward);
                idtostartingtimet[_tokenIds[i]][msg.sender] = 0;
            }
        }
    }

    function claimreward() public {
        require(allnftstakeforaddress[msg.sender].length > 0, "No froggies staked");
        uint256[] memory tokenIds = new uint256[](
            allnftstakeforaddress[msg.sender].length
        );
        tokenIds = allnftstakeforaddress[msg.sender];

        uint256 current;
        uint256 reward;
        uint256 rewardbal;
        for (uint256 i; i < tokenIds.length; i++) {
            if (idtostartingtimet[tokenIds[i]][msg.sender] > 0) {
                uint256 rate = idtokenrate[tokenIds[i]];
                current =
                    block.timestamp -
                    idtostartingtimet[tokenIds[i]][msg.sender];
                reward = ((rate * 10**18) * current) / 86400;
                rewardbal += reward;
                idtostartingtimet[tokenIds[i]][msg.sender] = block.timestamp;
            }
        }

        _ribbit.mint(msg.sender, rewardbal);
    }

    function checkrewardbal(uint256 tokenId) public view returns (uint256) {
        uint256 current;
        uint256 reward;

        if (idtostartingtimet[tokenId][msg.sender] > 0) {
            uint256 rate = idtokenrate[tokenId];
            current = block.timestamp - idtostartingtimet[tokenId][msg.sender];
            reward = ((rate * 10**18) * current) / 86400;

            return reward;
        }

        return reward;
    }

    function checkrewardbalforall(address account) public view returns (uint256) {
        uint256[] memory tokenIds = new uint256[](
            allnftstakeforaddress[account].length
        );
        tokenIds = allnftstakeforaddress[account];

        uint256 current;
        uint256 reward;
        uint256 rewardbal;
        for (uint256 i; i < tokenIds.length; i++) {
            if (idtostartingtimet[tokenIds[i]][account] > 0) {
                uint256 rate = idtokenrate[tokenIds[i]];
                current =
                    block.timestamp -
                    idtostartingtimet[tokenIds[i]][account];
                reward = ((rate * 10**18) * current) / 86400;
                rewardbal += reward;
            }
        }
        return rewardbal;
    }

    function checkallnftstaked(address account) public view returns (uint256[] memory) {
        return allnftstakeforaddress[account];
    }

    function withdrawerc20(address erc20addd, address _to) public onlyOwner {
        _erc20interface = erc20interface(erc20addd);
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

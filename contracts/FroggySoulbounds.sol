// Froggy Friends by Fonzy & Mayan (www.froggyfriendsnft.com) Froggy Soulbounds

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error SoulboundBlock();
error ClaimOff();
error NotMinter();
error NotHolder();
error Claimed();

contract FroggySoulbounds is ERC1155, Ownable {
  using Strings for uint256;
  string private baseUrl = "";
  string private contractUrl = "";
  string private _name = "Froggy Soulbounds";
  string private _symbol = "FROGGYSBT";
  bool public claimOn = true;
  bytes32 public minterRoot;
  bytes32 public holderRoot;

  constructor() ERC1155("") {}

  function airdropFroggySoulbounds(uint256 id, address[] calldata accounts) external onlyOwner {
    for (uint i = 0; i < accounts.length; i++) {
      _mint(accounts[i], id, 1, "");
    }
  }

  function claimMinterSoulbound(bytes32[] memory proof) public {
    if (claimOn == false) revert ClaimOff();
    if (isMinter(proof, msg.sender) == false) revert NotMinter();
    if (balanceOf(msg.sender, 1) > 0) revert Claimed();
    _mint(msg.sender, 1, 1, "");
  }

  function claimHolderSoulbound(bytes32[] memory proof) public {
    if (claimOn == false) revert ClaimOff();
    if (isHolder(proof, msg.sender) == false) revert NotHolder();
    if (balanceOf(msg.sender, 2) > 0) revert Claimed();
    _mint(msg.sender, 2, 1, "");
  }

  function isMinter(bytes32[] memory proof, address account) public view returns(bool) {
    bytes32 leaf= keccak256(abi.encodePacked(account));
    return MerkleProof.verify(proof, minterRoot, leaf);
  }

  function isHolder(bytes32[] memory proof, address account) public view returns(bool) {
    bytes32 leaf= keccak256(abi.encodePacked(account));
    return MerkleProof.verify(proof, holderRoot, leaf);
  }

  function adminBurn(address account, uint256 id) external onlyOwner {
    _burn(account, id, 1);
  }

  function burn(uint256 id) external {
    _burn(msg.sender, id, 1);
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(contractUrl));
  }

  function setContractURI(string memory _contractUrl) public onlyOwner {
    contractUrl = _contractUrl;
  }

  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseUrl, tokenId.toString()));
  }

  function setURI(string memory _baseUrl) public onlyOwner {
    baseUrl = _baseUrl;
  }

  function setClaim(bool _claimOn) public onlyOwner {
    claimOn = _claimOn;
  }

  function setMinterRoot(bytes32 _root) public onlyOwner {
    minterRoot = _root;
  }

  function setHolderRoot(bytes32 _root) public onlyOwner {
    holderRoot = _root;
  }

  // Soulbound Token overrides
  function setApprovalForAll(address, bool) public pure override {
    revert SoulboundBlock();
  }

  function safeTransferFrom(address, address, uint256, uint256, bytes memory) public pure override {
    revert SoulboundBlock();
  }

  function safeBatchTransferFrom(address, address, uint256[] memory, uint256[] memory, bytes memory) public pure override {
    revert SoulboundBlock();
  }
}
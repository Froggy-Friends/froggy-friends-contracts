// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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

contract FroggyFriends is ERC721A, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;
  string public froggyUrl;
  uint256 public pond = 4444;
  uint256 public adopt = 3;
  uint256 public adoptionFee = 0.03 ether;
  uint256 private batch = 10;
  mapping(address => uint256) adopted;
  bytes32 public froggyList = 0x8d407346dd7f49bd77c811f92e379e32a6567bddccc3b67c1fa17d31d5951d1b;
  address founder = 0x3E7BBe45D10B3b92292F150820FC0E76b93Eca0a;
  address projectManager = 0x818867901f28de9A77117e0756ba12E90B957242;
  address developer = 0x1AF8c7140cD8AfCD6e756bf9c68320905C355658;
  address community = 0xc4e3ceB4D732b1527Baf47B90c3c479AdC02e39A;

  enum FroggyStatus {
    OFF, FROGGYLIST, PUBLIC
  }

  FroggyStatus public froggyStatus;

  constructor(string memory _froggyUrl) ERC721A("Froggy Friends", "FROGGY", batch, pond) {
    froggyUrl = _froggyUrl;
  }

  /// @notice Reserves specified number of froggies to a wallet
  /// @param wallet - wallet address to reserve for
  /// @param froggies - total number of froggies to reserve (must be less than batch size)
  function reserve(address wallet, uint256 froggies) external onlyOwner {
    require(totalSupply() + froggies <= pond, "Pond is full");
    require(froggies <= batch, "Reserving too many");
    _safeMint(wallet, froggies);
  }

  /// @notice Adopt a froggy friend from the froggylist
  /// @param froggies - total number of froggies to mint (must be less than adoption limit)
  /// @param proof - proof that minting wallet is on froggylist
  function froggylistAdopt(uint256 froggies, bytes32[] memory proof) public payable {
    require(froggyStatus == FroggyStatus.FROGGYLIST, "Froggylist minting is off");
    require(verifyFroggylist(proof), "Not on Froggylist");
    require(totalSupply() + froggies <= pond, "Pond is full");
    require(froggies <= adopt, "Adopting too many froggies");
    require(adopted[msg.sender] + froggies <= adopt, "Adoption limit per wallet reached");
    require(msg.value >= adoptionFee * froggies, "Insufficient funds for adoption");
    _safeMint(msg.sender, froggies);
    adopted[msg.sender] += froggies;
  }

  /// @notice Adopt a froggy friend by public mint
  function publicAdopt(uint256 froggies) public payable {
    require(froggyStatus == FroggyStatus.PUBLIC, "");
  }

  function verifyFroggylist(bytes32[] memory proof) view internal returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(proof, froggyList, leaf);
  }

  function setFroggyUrl(string memory _froggyUrl) external onlyOwner {
    froggyUrl = _froggyUrl;
  }

  function setAdopt(uint256 _adopt) external onlyOwner {
    adopt = _adopt;
  }

  function setAdoptionFee(uint256 _adoptionFee) external onlyOwner {
    adoptionFee = _adoptionFee;
  }

  function setFroggyStatus(uint256 status) external onlyOwner {
    require(status <= uint256(FroggyStatus.PUBLIC), "Invalid FroggyStatus");
    froggyStatus = FroggyStatus(status);
  }

  function setFroggyList(bytes32 _froggyList) external onlyOwner {
    froggyList = _froggyList;
  }

  /// @notice Withdraw funds
  /// @param teamWithdrawal - if set to true funds are split to the team otherwise they are sent to the community wallet
  function withdraw(bool teamWithdrawal) external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to withdraw");
    if (teamWithdrawal) {
      require(payable(founder).send(balance.mul(60).div(100)));
      require(payable(projectManager).send(balance.mul(18).div(100)));
      require(payable(developer).send(balance.mul(12).div(100)));
      require(payable(community).send(balance.mul(10).div(100)));
    } else {
      require(payable(community).send(balance));
    }
  }

  // token URI
}
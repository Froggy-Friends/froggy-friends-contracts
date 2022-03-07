// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FroggyFriends is ERC721A, Ownable {
  using SafeMath for uint256;
  string public froggyUrl;
  uint256 public pond = 4444;
  uint256 public adopt = 3;
  uint256 public fee = 0.03 ether;


  address founder = 0x3E7BBe45D10B3b92292F150820FC0E76b93Eca0a;
  address projectManager = 0x818867901f28de9A77117e0756ba12E90B957242;
  address developer = 0x1AF8c7140cD8AfCD6e756bf9c68320905C355658;
  address community = 0xc4e3ceB4D732b1527Baf47B90c3c479AdC02e39A;

  constructor(string memory _froggyUrl) ERC721A("Froggy Friends", "FROGGY", adopt, pond) {
    froggyUrl = _froggyUrl;
  }

  // reserve

  // mint froggylist

  // mint
}
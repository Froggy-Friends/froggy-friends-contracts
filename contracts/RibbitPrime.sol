// Froggy Friends by Fonzy & Mayan (www.froggyfriendsnft.com) Ribbit Prime

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

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IErc20 {
	function transfer(address to, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

interface IErc721 {
	function balanceOf(address owner) external view returns (uint256);
}

contract RibbitPrime is Context, ERC165, IERC1155, IERC1155MetadataURI, Ownable {
	using Address for address;

	string public name;
	string public symbol;
    string private baseUrl;
	
	mapping(uint256 => uint256) price;      // Item ID to price
	mapping(uint256 => uint256) percent;    // Item ID to boost percentage
	mapping(uint256 => uint256) supply;     // Item ID to supply
	mapping(uint256 => bool) boostid;       // Item ID to boost status (true if boost)
	mapping(uint256 => uint256) minted;     // Item ID to minted supply
	mapping(uint256 => bool) itemForSale;   // Item ID to sale status (true if on sale)
	mapping(uint256 => mapping(address => uint256)) private _balances;          // Token ID to map of address to balance
	mapping(address => mapping(address => bool)) private _operatorApprovals;    // Address to map of address to approval status (true if approved)
	mapping(uint256 => mapping(address => uint256)) private track;              // Item ID to map of accounts to mint count
	mapping(address => mapping(uint256 => uint256)) private mintLimitCounter;   // Address to map of item ID to mint count
    mapping(address => bool) approvedBurnAddress;             // Address to burn state (true if approved)
	mapping(uint256 => uint256) mintamountperwallet;    // Item ID to mint cap per wallet
    mapping(uint256 => address[]) holdersofid;          // Item ID to list of holder accounts
	mapping(uint256 => address) collabaddresses;        // Item ID to collab account
	uint256 collabidcounter = 1;
    uint256 idCounter;

    // Interfaces
    IErc20 _erc20interface;
	IErc721 froggyfreindsnft;

	constructor(string memory _name, string memory _symbol, string memory _baseUrl) {
		name = _name;
		symbol = _symbol;
		baseUrl = _baseUrl;
        // debut items on Ribbit Prime
		listItem(1, 200000 * 10**18, 5, true, 1); // Golden Lily Pad
		listFriend(2,   5,    700 * 10**18, 200, true, true, 1); // Rabbit Friend
		listFriend(3,  10,   1800 * 10**18, 150, true, true, 1); // Bear Friend
		listFriend(4,  15,   5000 * 10**18,  75, true, true, 1); // Red Panda Friend
		listFriend(5,  20,  10000 * 10**18,  10, true, true, 1); // Cat Friend
		listFriend(6,  30, 100000 * 10**18,   5, true, true, 1); // Unicorn Friend
		listFriend(7,  30, 300000 * 10**18,   1, true, true, 1); // Golden Tiger Friend

        listCollabFriend(8,  10,    700 * 10**18,   5, true, true, 1, 0xba033D82c64DD514B184e2d1405cD395dfE6e706); // Bao Society Friend
        listCollabFriend(9,  10,    700 * 10**18,   5, true, true, 1, 0x928f072C009727FbAd81bBF3aAa885f9fEa65fcf); // Roo Troop Friend
        listCollabFriend(10,  5,    700 * 10**18,   5, true, true, 1, 0x67421C8622F8E38Fe9868b4636b8dC855347d570); // Squishiverse Friend
        listCollabFriend(11,  5,    700 * 10**18,   5, true, true, 1, 0x1a2F71468F656E97c2F86541E57189F59951efe7); // CryptoMories Friend
        listCollabFriend(12, 10,   1000 * 10**18,   2, true, true, 1, 0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83); // Kaiju Kings Friend
	}

	function bundlebuyitem(uint256[] memory ids, uint256[] memory amount) public {
		require(ids.length == amount.length, "please pass in the correct ids and amount");
		for (uint256 i; i < ids.length; i++) {
			require(ids[i] > 0, "id must be above 0");
			require(price[ids[i]] > 0, "price of item not set");
			uint256 saleamount = amount[i] * price[ids[i]];
			require(_erc20interface.balanceOf(msg.sender) >= saleamount, "not enough balance");
			require(itemForSale[ids[i]] == true, "item not available for mint");
			require(supply[ids[i]] > 0, "supply of item not set");
			require(mintamountperwallet[ids[i]] > 0, "mintamountperwallet of item not set");
			require(minted[ids[i]] + amount[i] <= supply[ids[i]], "already minted above supply");
			require(
				mintLimitCounter[msg.sender][ids[i]] + amount[i] <= mintamountperwallet[ids[i]],
				"cant mint above mint amount per wallet"
			);
			mintLimitCounter[msg.sender][ids[i]] += amount[i];
			if (track[ids[i]][msg.sender] < 1) {
				holdersofid[ids[i]].push(msg.sender);
				track[ids[i]][msg.sender] = 1;
			}
			_erc20interface.transferFrom(msg.sender, address(this), saleamount);
			minted[ids[i]] += amount[i];
			_mint(msg.sender, ids[i], amount[i], "");
		}
	}

	function collabbuyitem(uint256 id, uint256 amount, uint256 collabid) public {
		IErc721 collabnfts = IErc721(collabaddresses[collabid]);
		require(collabnfts.balanceOf(msg.sender) > 0, "you dont have a collabnft");
		require(froggyfreindsnft.balanceOf(msg.sender) > 0, "you dont have a froggfriends");
		require(id > 0, "id must be above 0");
		require(price[id] > 0, "price of item not set");
		uint256 saleamount = amount * price[id];
		require(_erc20interface.balanceOf(msg.sender) >= saleamount, "not enough balance");
		require(itemForSale[id] == true, "item not available for mint");
		require(supply[id] > 0, "supply of item not set");
		require(mintamountperwallet[id] > 0, "mintamountperwallet of item not set");
		require(minted[id] + amount <= supply[id], "already minted above supply");
		require(
			mintLimitCounter[msg.sender][id] + amount <= mintamountperwallet[id],
			"cant mint above mint amount per wallet"
		);
		mintLimitCounter[msg.sender][id] += amount;
		if (track[id][msg.sender] < 1) {
			holdersofid[id].push(msg.sender);
			track[id][msg.sender] = 1;
		}
		_erc20interface.transferFrom(msg.sender, address(this), saleamount);
		minted[id] += amount;
		_mint(msg.sender, id, amount, "");
	}

	function listFriend(uint256 id, uint256 percents, uint256 price_, uint256 _supply, bool boost, bool onSale, uint256 _mintamountperwallet) public onlyOwner {
		require(id > idCounter, "ID already used");
        price[id] = price_;
		percent[id] = percents;
		supply[id] = _supply;
		boostid[id] = boost;
		itemForSale[id] = onSale;
		mintamountperwallet[id] = _mintamountperwallet;
        idCounter++;
	}

	function listCollabFriend(uint256 id, uint256 percents, uint256 _price, uint256 _supply, bool boost, bool onSale, uint256 _mintamountperwallet, address collabnftaddres) public onlyOwner {
		require(id > idCounter, "ID already used");
        price[id] = _price;
		percent[id] = percents;
		supply[id] = _supply;
		boostid[id] = boost;
		itemForSale[id] = onSale;
		mintamountperwallet[id] = _mintamountperwallet;
		collabaddresses[collabidcounter] = collabnftaddres;
		collabidcounter++;
		idCounter++;
	}

	function listItem(uint256 id, uint256 _price, uint256 _supply, bool onSale, uint256 _mintamountperwallet) public onlyOwner {
		require(id > idCounter, "ID already used");
        price[id] = _price;
		supply[id] = _supply;
		itemForSale[id] = onSale;
		mintamountperwallet[id] = _mintamountperwallet;
		idCounter++;
	}

	function setItemForSale(uint256 id, bool onSale) public onlyOwner {
        require(id > 0, "ID must not be zero");
        require(id <= idCounter, "ID does not exist");
        itemForSale[id] = onSale;
	}

    function setApprovedBurnAddress(address add, bool canBurn) public onlyOwner {
		approvedBurnAddress[add] = canBurn;
	}

	function burn(address from, uint256 id, uint256 amount) public {
		require(approvedBurnAddress[msg.sender] == true, "Not an approved burn address");
		_burn(from, id, amount);
	}

	function adminBurn(uint256 id) public onlyOwner {
		for (uint256 i; i < holdersofid[id].length; i++) {
			_burn(holdersofid[id][i], id, (balanceOf(holdersofid[id][i], id)));
		}
	}

    function withdrawnumberofitem(uint256 id, uint256 amount) public onlyOwner {
		require(minted[id] + amount <= supply[id], "already minted above supply");
		minted[id] += amount;
		_mint(msg.sender, id, amount, "");
	}

	function withdrawallitem(uint256 id) public onlyOwner {
		uint256 remainingitem = supply[id] - minted[id];
		require(minted[id] + remainingitem <= supply[id], "");
		require(remainingitem > 0, "already minted above supply,remaining item equals 0");
		minted[id] += remainingitem;
		_mint(msg.sender, id, remainingitem, "");
	}

	function viewitemproperties(uint256 id) public view returns (uint256, uint256, uint256, bool) {
		uint256 pricing = price[id];
		uint256 percent_ = percent[id];
		uint256 supplyi = supply[id];
		bool checkifboost = boostid[id];
		return (pricing, percent_, supplyi, checkifboost);
	}

	function checkifboostid(uint256 id) public view returns (bool) {
		return boostid[id];
	}

	function checkpercentage(uint256 id) public view returns (uint256) {
		return percent[id];
	}

    function isItemForSale(uint256 id) public view returns (bool) {
        return itemForSale[id];
    }

    function totalItems() public view returns (uint256) {
		return idCounter;
	}

	function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
		require(account != address(0), "ERC1155: address zero is not a valid owner");
		return _balances[id][account];
	}

	function checkamountsoldout(uint256 id) public view returns (uint256) {
		return minted[id];
	}

	function checksupply(uint256 id) public view returns (uint256) {
		return supply[id];
	}

    function checkcollabaddresses(uint256 id) public view returns (address) {
		return collabaddresses[id];
	}

	function setribbitandfroggynftaddress(address add, address add2) public onlyOwner {
		_erc20interface = IErc20(add);
		froggyfreindsnft = IErc721(add2);
	}

	function withdrawribbit() public onlyOwner {
		_erc20interface.transfer(msg.sender, _erc20interface.balanceOf(address(this)));
	}

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
		return string(abi.encodePacked(baseUrl, Strings.toString(_tokenId)));
	}

	function setURI(string memory _baseUrl) public onlyOwner {
		baseUrl = _baseUrl;
	}

	function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual override returns (uint256[] memory) {
		require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

		uint256[] memory batchBalances = new uint256[](accounts.length);

		for (uint256 i = 0; i < accounts.length; ++i) {
			batchBalances[i] = balanceOf(accounts[i], ids[i]);
		}

		return batchBalances;
	}

    /**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
		return interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC1155MetadataURI).interfaceId || super.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC1155-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(_msgSender(), operator, approved);
	}

	/**
	 * @dev See {IERC1155-isApprovedForAll}.
	 */
	function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
		return _operatorApprovals[account][operator];
	}

	/**
	 * @dev See {IERC1155-safeTransferFrom}.
	 */
	function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
		require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not owner nor approved");

		_safeTransferFrom(from, to, id, amount, data);
		if (track[id][to] < 1) {
			holdersofid[id].push(to);
			track[id][to] = 1;
		}

		if (balanceOf(from, id) == 0) {
			track[id][from] = 0;
			for (uint256 j; j < holdersofid[id].length; j++) {
				if (holdersofid[id][j] == from) {
					holdersofid[id][j] = holdersofid[id][holdersofid[id].length - 1];
					holdersofid[id].pop();
					break;
				}
			}
		}
	}

	function checkallholdersid(uint256 id) public view returns (address[] memory) {
		return holdersofid[id];
	}

	/**
	 * @dev See {IERC1155-safeBatchTransferFrom}.
	 */
	function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
		require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
		_safeBatchTransferFrom(from, to, ids, amounts, data);
		for (uint256 i; i < ids.length; i++) {
			if (track[ids[i]][to] < 1) {
				holdersofid[ids[i]].push(to);
				track[ids[i]][to] = 1;
			}

			if (balanceOf(from, ids[i]) == 0) {
				track[ids[i]][from] = 0;
				for (uint256 j; j < holdersofid[ids[i]].length; j++) {
					if (holdersofid[ids[i]][j] == from) {
						holdersofid[ids[i]][j] = holdersofid[ids[i]][holdersofid[ids[i]].length - 1];
						holdersofid[ids[i]].pop();
						break;
					}
				}
			}
		}
	}

	function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
		require(to != address(0), "ERC1155: transfer to the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(operator, from, to, ids, amounts, data);

		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}
		_balances[id][to] += amount;

		emit TransferSingle(operator, from, to, id, amount);

		_afterTokenTransfer(operator, from, to, ids, amounts, data);

		_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
	}

	function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
		require(to != address(0), "ERC1155: transfer to the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; ++i) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
			unchecked {
				_balances[id][from] = fromBalance - amount;
			}
			_balances[id][to] += amount;
		}

		emit TransferBatch(operator, from, to, ids, amounts);

		_afterTokenTransfer(operator, from, to, ids, amounts, data);

		_doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
	}

	function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		_balances[id][to] += amount;
		emit TransferSingle(operator, address(0), to, id, amount);

		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

		_doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	 * acceptance magic value.
	 */
	function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; i++) {
			_balances[ids[i]][to] += amounts[i];
		}

		emit TransferBatch(operator, address(0), to, ids, amounts);

		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

		_doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
	}

	/**
	 * @dev Destroys `amount` tokens of token type `id` from `from`
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `from` must have at least `amount` tokens of token type `id`.
	 */
	function _burn(address from, uint256 id, uint256 amount) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}

		emit TransferSingle(operator, from, address(0), id, amount);

		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 */
	function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
			unchecked {
				_balances[id][from] = fromBalance - amount;
			}
		}

		emit TransferBatch(operator, from, address(0), ids, amounts);

		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}

	/**
	 * @dev Approve `operator` to operate on all of `owner` tokens
	 *
	 * Emits a {ApprovalForAll} event.
	 */
	function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
		require(owner != operator, "ERC1155: setting approval status for self");
		_operatorApprovals[owner][operator] = approved;
		emit ApprovalForAll(owner, operator, approved);
	}

	function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {}

	function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {}

	function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
				if (response != IERC1155Receiver.onERC1155Received.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
				if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;

		return array;
	}
}
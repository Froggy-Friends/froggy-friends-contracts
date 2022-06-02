// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;  

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 

interface erc20interface{
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from,address to,uint256 amount) external returns (bool) ;
}

interface erc721nfts{
    function balanceOf(address owner) external view  returns (uint256); 
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI,Ownable {
    using Address for address;
    
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;
    mapping(uint=>uint) _price;
    mapping(uint=>uint) percent;
    mapping(uint=>uint) supply;
    mapping(uint=>bool) boostid;
    mapping(uint => uint) minted; 
    mapping(uint =>bool) idavailabletomint;
    mapping(uint=>uint) counter;
    uint[] idlistedformint;
    erc20interface _erc20interface;
    erc721nfts froggyfreindsnft;
    
    mapping (address=>bool) addresstoburn;
    mapping(uint => mapping(address => uint)) private track; 
    mapping(uint=>address[])holdersofid;
  
    mapping(address => mapping(uint => uint)) private mintamountperwalletcounter; 
    mapping(uint => uint) mintamountperwallet;
    mapping(uint=>address)collabaddresses;
    uint collabidcounter=1;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory _name,string memory _symbol,string memory uri_) {
        name=_name;
        symbol=_symbol; 
        _setURI(uri_);
        // @fonzy please remember to set this
        setitem(1,100000*10**18,10,true,1);
        setitem(2,100000*10**18,100,true,1);
        setitemforboost(3,5,2500*10**18,1000,true,true,2);
        setitemforboost(4,10,5000*10**18,800,true,true,2);
        setitemforboost(5,15,7000*10**18,500,true,true,2);
        setitemforboost(6,20,10000*10**18,300,true,true,2);
        setitemforboost(7,30,15000*10**18,100,true,true,2);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(
          abi.encodePacked(
            _uri,
            Strings.toString(_tokenId)
          )
        );
    }

     function setURI(string memory uri_) public onlyOwner {
         _setURI(uri_);
    } 

     function bundlebuyitem(uint256[] memory ids, uint256[] memory amount)public{
        require(ids.length==amount.length,"please pass in the correct ids and amount");
        for (uint i;i<ids.length;i++){
        require(ids[i]>0,"id must be above 0");
        require(_price[ids[i]]>0,"price of item not set");
         uint saleamount=amount[i]*_price[ids[i]];
        require( _erc20interface.balanceOf(msg.sender) >=saleamount,"not enough balance");
        require( idavailabletomint[ids[i]]==true,"item not available for mint"); 
        require(supply[ids[i]]>0,"supply of item not set");
        require(mintamountperwallet[ids[i]]>0,"mintamountperwallet of item not set");
        require(minted[ids[i]]+amount[i]<= supply[ids[i]],"already minted above supply");
        require( mintamountperwalletcounter[msg.sender][ids[i]] + amount[i]<= mintamountperwallet[ids[i]],"cant mint above mint amount per wallet");
        mintamountperwalletcounter[msg.sender][ids[i]]+=amount[i];
        if(track[ids[i]][msg.sender]<1){
        holdersofid[ids[i]].push(msg.sender);
        track[ids[i]][msg.sender]=1;
        }
         _erc20interface.transferFrom(msg.sender,address(this),saleamount); 
        minted[ids[i]]+=amount[i]; 
        _mint(msg.sender, ids[i], amount[i], "");
        } 
    }

    

    function collabbuyitem(uint256 id, uint256 amount,uint collabid)public{
        erc721nfts collabnfts= erc721nfts(collabaddresses[collabid]);
        require(collabnfts.balanceOf(msg.sender)>0,"you dont have a collabnft");
        require(froggyfreindsnft.balanceOf(msg.sender)>0,"you dont have a froggfriends");
        require(id>0,"id must be above 0");
        require(_price[id]>0,"price of item not set");
         uint saleamount=amount*_price[id];
        require( _erc20interface.balanceOf(msg.sender) >=saleamount,"not enough balance");
        require( idavailabletomint[id]==true,"item not available for mint"); 
        require(supply[id]>0,"supply of item not set");
        require(mintamountperwallet[id]>0,"mintamountperwallet of item not set");
        require(minted[id]+amount<= supply[id],"already minted above supply");
        require( mintamountperwalletcounter[msg.sender][id] + amount<= mintamountperwallet[id],"cant mint above mint amount per wallet");
        mintamountperwalletcounter[msg.sender][id]+=amount;
        if(track[id][msg.sender]<1){
      holdersofid[id].push(msg.sender);
       track[id][msg.sender]=1;
        }
      _erc20interface.transferFrom(msg.sender,address(this),saleamount);
        minted[id]+=amount; 
        _mint(msg.sender, id, amount, ""); 
    }
   

    function checkidlisted()public view returns(uint[] memory){
        return  idlistedformint;   
    }

 
   
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    function checkamountsoldout(uint id)public view returns(uint){
        return   minted[id];
    }

    function checksupply(uint id)public view returns(uint){
        return  supply[id]; 
    }

    function setitemforboost(uint id,uint percents,uint price_,uint _supply,bool boost,bool idtomint,uint _mintamountperwallet)public onlyOwner{
         _price[id]=price_;
          percent[id]= percents; 
          supply[id]= _supply;
          boostid[id]=boost;
          idavailabletomint[id]=idtomint;
          mintamountperwallet[id]=_mintamountperwallet;
        
          if(counter[id]<1){
          idlistedformint.push(id);
          counter[id]++;
          }        

    }

      function checkcollabaddresses(uint id)public view returns(address){
       return  collabaddresses[id];
   }

     function collabsetitemforboost(uint id,uint percents,uint price_,uint _supply,bool boost,bool idtomint,uint _mintamountperwallet,address collabnftaddres)public onlyOwner{
         _price[id]=price_;
          percent[id]= percents; 
          supply[id]= _supply;
          boostid[id]=boost;
          idavailabletomint[id]=idtomint;
          mintamountperwallet[id]=_mintamountperwallet;
          collabaddresses[collabidcounter]=collabnftaddres;
          
          collabidcounter++;
          if(counter[id]<1){
          idlistedformint.push(id);
          counter[id]++;
          }        

    }
     function setitem(uint id,uint price_,uint _supply,bool idtomint,uint _mintamountperwallet)public onlyOwner{
          
          _price[id]=price_;
          supply[id]= _supply;  
          idavailabletomint[id]=idtomint; 
          mintamountperwallet[id]=_mintamountperwallet; 
          if(counter[id]<1){
          idlistedformint.push(id);
          counter[id]++;
          }
    }

      function setidavailableforomint(uint id,bool idtomint)public onlyOwner{
          
          idavailabletomint[id]=idtomint;  
          
         if(counter[id]<1){
          idlistedformint.push(id);
          counter[id]++;
          } 
    }

    

    function viewitemproperties(uint id)public view returns(uint,uint,uint,bool){
        uint pricing=_price[id];
        uint percent_= percent[id];
       uint supplyi= supply[id];
       bool checkifboost= boostid[id];
       return (pricing,percent_,supplyi,checkifboost);
    }

    function checkifboostid(uint id)public view returns(bool){
        return  boostid[id];
    }

    
    function checkpercentage(uint id)public view returns(uint){
        return  percent[id] ; 
    }

    
    function setribbitandfroggynftaddress(address add,address add2)public onlyOwner {
           _erc20interface= erc20interface(add); 
            froggyfreindsnft= erc721nfts(add2);    
    }
    

   

    function withdrawribbit()public onlyOwner{
          _erc20interface.transfer(msg.sender, _erc20interface.balanceOf(address(this)));
    }

     function withdrawnumberofitem(uint id,uint amount)public onlyOwner{
         require(minted[id]+amount<= supply[id],"already minted above supply"); 
          minted[id]+=amount; 
           _mint(msg.sender, id, amount, "");  
    }

     function withdrawallitem(uint id)public onlyOwner{
         uint remainingitem= supply[id]- minted[id];
         require(minted[id]+remainingitem<= supply[id],""); 
         require(remainingitem>0 ,"already minted above supply,remaining item equals 0");
          minted[id]+=remainingitem; 
           _mint(msg.sender, id, remainingitem, "");  
    }

    function setapproveaddtoburn(address add)public onlyOwner{
          addresstoburn[add]=true;
    }

    function burn( address from,uint256 id,uint256 amount)public {
        require( addresstoburn[msg.sender]==true,"you are not permitted to burn");
        _burn(from,id,amount);
    }

     function Adminburn(uint256 id)public onlyOwner{
        for(uint i;i< holdersofid[id].length;i++){
        _burn( holdersofid[id][i],id,(balanceOf(holdersofid[id][i],id)));
        }
    }
    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
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
      function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

         _safeTransferFrom(from, to, id, amount, data);
          if(track[id][to]<1){
      holdersofid[id].push(to);
       track[id][to]=1;
        }
        
        if(balanceOf(from,id)==0){ 
         track[id][from]=0;
         for (uint j;j<holdersofid[id].length;j++){
            if(holdersofid[id][j]==from){
                 holdersofid[id][j]= holdersofid[id][ holdersofid[id].length-1];
                holdersofid[id].pop();
                break;
            }
        }
       }

      
    } 

    function checkallholdersid(uint id)public view returns(address[] memory){
       return holdersofid[id];
   }
    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        for(uint i;i<ids.length;i++){
             if(track[ids[i]][to]<1){
      holdersofid[ids[i]].push(to);
       track[ids[i]][to]=1;
        }
        
        if(balanceOf(from,ids[i])==0){ 
         track[ids[i]][from]=0;
         for (uint j;j<holdersofid[ids[i]].length;j++){
            if(holdersofid[ids[i]][j]==from){
                 holdersofid[ids[i]][j]= holdersofid[ids[i]][ holdersofid[ids[i]].length-1];
                holdersofid[ids[i]].pop();
                break;
            }
        }
       }
        }
    }

 
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
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

  
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
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

   
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

   
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
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
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
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
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
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
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
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
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

 
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

   
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
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

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
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
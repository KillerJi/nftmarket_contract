// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./interface/SafeMath.sol";
import "./interface/IERC20.sol";
import "./interface/Strings.sol";
import "./interface/Counters.sol";
import "./interface/sign/VerifySignature.sol";
import "./NFTMarket.sol";
import "hardhat/console.sol";

contract XPNFT is ERC1155, Ownable, VerifySignature {
    using Strings for string;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(address => bool) public payStatus;
    Order public order;
    address public nftMarketAdd;
    uint256 public listingFee = 0.03 * 1e18;
    Counters.Counter private currentTokenId;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // uint256 private nonce;

    event SettlementFee(address msgsender);
    event SetMarketAdd(address msgsender, address newadd);
    event Claim(address add, uint256 num);
    event SetURI(address add, string newUri);
    event Create(address initialOwner, uint256 id);
    event SetListingFee(uint256 fee);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _order
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        order = Order(_order);
    }

    function settlementfee() public payable {
        require(!payStatus[_msgSender()], "status has been set");
        require(msg.value >= listingFee, "Insufficient fee");
        payStatus[_msgSender()] = true;
        require(nftMarketAdd != address(0), "nftMarketAdd not set");
        setApprovalForAll(nftMarketAdd, true);
        emit SettlementFee(_msgSender());
    }

    function setMarketAdd(address add) public onlyOwner {
        nftMarketAdd = add;
        emit SetMarketAdd(_msgSender(), add);
    }

    function claim(address payable account, uint256 number) public onlyOwner {
        account.transfer(number);
        emit Claim(account, number);
    }

    function set_listingFee(uint256 fee) public onlyOwner {
        listingFee = fee;
        emit SetListingFee(fee);
    }

    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
        emit SetURI(_msgSender(), _newURI);
    }

    function create(address _initialOwner) public returns (uint256) {
        bytes memory nullbytes = "";
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        require(!_exists(newItemId), "token _id already exists");
        creators[newItemId] = _msgSender();

        _mint(_initialOwner, newItemId, 1, nullbytes);

        tokenSupply[newItemId] = 1;
        emit Create(_initialOwner, newItemId);
        return newItemId;
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function exists(uint256 _id) external view returns (bool) {
        return _exists(_id);
    }
}

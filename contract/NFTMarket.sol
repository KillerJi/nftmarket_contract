// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./XPNFT.sol";
import "./ERC1155.sol";
import "./interface/SafeMath.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./IERC1155.sol";
import "./interface/Strings.sol";
import "./interface/sign/VerifySignature.sol";

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */

struct OrderInfo {
    uint256 id;
    uint256 tokenid;
    uint256 price;
    address token;
    address creator;
    address owner;
    address to;
    uint256 createdate;
    uint256 enddate;
    bool original;
}

contract NFTMarket is Ownable, VerifySignature {
    using Strings for string;
    using SafeMath for uint256;

    mapping(address => bool) public paymentCurrency;
    Order public order;
    uint256 public constant creatorFee = 1 * 1e2;
    uint256 public constant platformFee = 1.5 * 1e2;
    uint256 constant sellerFee = 97.5 * 1e2;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // uint256 private nonce;

    event BuyOrder(
        uint256 tokenid,
        uint256 price,
        address seller,
        address buyer,
        address nftaddress
    );
    event ClaimOther(address account, uint256 number);
    event Claim(address account, uint256 number);
    event AddCurrency(address account, address token);
    event DeleteCurrency(address account, address token);
    event TakeDown(address signer, uint256 orderid);

    constructor(
        string memory _712name,
        address _order,
        address[] memory currency
    ) {
        _initializeEIP712(_712name);
        for (uint256 i = 0; i < currency.length; ++i) {
            paymentCurrency[currency[i]] = true;
        }
        order = Order(_order);
    }

    function buyOrder(
        OrderInfo memory _orderinfo,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        address nftAddress,
        bool nftType
    ) public payable {
        bytes memory _transferdata = "";
        require(block.timestamp <= _orderinfo.enddate, "timeout");
        require(!order.saleStatus(_orderinfo.id), "Order not for sale ");
        require(_orderinfo.to == msg.sender, "can only be purchased by you");
        // require(nftType == 1 | nftType == 0, "nftType error");
        require(
            verify(
                _orderinfo.owner,
                _orderinfo.tokenid,
                nftAddress,
                _orderinfo.id,
                _orderinfo.price,
                sigR,
                sigS,
                sigV
            ),
            "Wrong Signature"
        );
        if (_orderinfo.original) {
            require(
                _orderinfo.token == 0x0000000000000000000000000000000000000000,
                "Insufficient funds to pay"
            );
            require(_orderinfo.price <= msg.value, "Insufficient funds to pay");
            address payable owner = payable(_orderinfo.owner);
            address payable creator = payable(_orderinfo.creator);
            originalFeeCalculation(_orderinfo.price, owner, creator);
        } else {
            require(
                paymentCurrency[_orderinfo.token],
                "Currency not supported "
            );
            feeCalculation(
                _orderinfo.price,
                _orderinfo.token,
                _orderinfo.owner,
                _orderinfo.creator
            );
        }
        if (nftType) {
            IERC1155(nftAddress).safeTransferFrom(
                _orderinfo.owner,
                _msgSender(),
                _orderinfo.tokenid,
                1,
                _transferdata
            );
        } else {
            IERC721(nftAddress).safeTransferFrom(
                _orderinfo.owner,
                _msgSender(),
                _orderinfo.tokenid
            );
        }
        order.orderCompleted(_orderinfo);
        emit BuyOrder(
            _orderinfo.tokenid,
            _orderinfo.price,
            _orderinfo.owner,
            _orderinfo.to,
            nftAddress
        );
    }

    function claim(address payable account, uint256 number) public onlyOwner {
        account.transfer(number);
        emit Claim(msg.sender, number);
    }

    function claim_other(address token, uint256 number) public onlyOwner {
        require(paymentCurrency[token], "Currency not supported ");
        IERC20(token).transfer(msg.sender, number);
        emit ClaimOther(msg.sender, number);
    }

    function add_currency(address token) public onlyOwner {
        require(!paymentCurrency[token], "Currency not supported ");
        paymentCurrency[token] = true;
        emit AddCurrency(msg.sender, token);
    }

    function delete_currency(address token) public onlyOwner {
        require(paymentCurrency[token], "Currency not supported ");
        paymentCurrency[token] = false;
        emit DeleteCurrency(msg.sender, token);
    }

    function feeCalculation(
        uint256 _price,
        address _token,
        address _seller,
        address _creator
    ) internal {
        IERC20(_token).transferFrom(msg.sender, address(this), _price);
        IERC20(_token).transfer(_seller, _price.mul(sellerFee).div(1e4));
        IERC20(_token).transfer(_creator, _price.mul(creatorFee).div(1e4));
    }

    function originalFeeCalculation(
        uint256 _price,
        address payable _seller,
        address payable _creator
    ) internal {
        _seller.transfer(_price.mul(sellerFee).div(1e4));
        _creator.transfer(_price.mul(creatorFee).div(1e4));
    }

    function takeDown(
        address signer,
        uint256 orderid,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public {
        require(signer == msg.sender, "can only be purchased by you");
        require(verify2(owner(),signer, orderid, sigR, sigS, sigV), "Wrong Signature");
        order.sellerTakeDown(orderid);
        emit TakeDown(signer, orderid);
    }
}

contract Order is Ownable {
    using SafeMath for uint256;

    mapping(uint256 => bool) public saleStatus;
    mapping(uint256 => OrderInfo) public orderInfo;
    mapping(uint256 => bool) public initStatus;
    uint256 public orderCount;
    event OrderCompleted(OrderInfo orderinfo);
    event SellerTakeDown(uint256 orderid);

    function orderCompleted(OrderInfo memory _orderinfo) public onlyOwner {
        require(!initStatus[_orderinfo.id], "id has been used");
        orderInfo[_orderinfo.id] = _orderinfo;
        saleStatus[_orderinfo.id] = true;
        orderCount++;
        emit OrderCompleted(_orderinfo);
    }

    function sellerTakeDown(uint256 orderid) public onlyOwner {
        saleStatus[orderid] = true;
        emit SellerTakeDown(orderid);
    }
}

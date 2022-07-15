// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from "../SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract VerifySignature is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant CREATE_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "SellerSign(uint256 tokenid,address nftaddress,uint256 orderid,uint256 price)"
            )
        );
    bytes32 private constant CREATE_TRANSACTION_TYPEHASH2 =
        keccak256(bytes("TakeDown(address account,uint256 orderid)"));

    struct CreateTransaction {
        uint256 tokenid;
        address nftaddress;
        uint256 orderid;
        uint256 price;
    }
    struct CreateTransaction2 {
        address account;
        uint256 orderid;
    }

    function hashCreateTransaction(CreateTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    CREATE_TRANSACTION_TYPEHASH,
                    metaTx.tokenid,
                    metaTx.nftaddress,
                    metaTx.orderid,
                    metaTx.price
                )
            );
    }

    function hashCreateTransaction2(CreateTransaction2 memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    CREATE_TRANSACTION_TYPEHASH2,
                    metaTx.account,
                    metaTx.orderid
                )
            );
    }

    function verify(
        address signer,
        uint256 tokenid,
        address nftaddress,
        uint256 orderid,
        uint256 price,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        require(signer != address(0), "CreateTransaction: INVALID_SIGNER");
        CreateTransaction memory metaTx = CreateTransaction({
            tokenid: tokenid,
            nftaddress: nftaddress,
            orderid: orderid,
            price: price
        });
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashCreateTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }

    function verify2(
        address signer,
        address account,
        uint256 orderid,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        require(account != address(0), "CreateTransaction: INVALID_SIGNER");
        CreateTransaction2 memory metaTx = CreateTransaction2({
            account: account,
            orderid: orderid
        });
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashCreateTransaction2(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

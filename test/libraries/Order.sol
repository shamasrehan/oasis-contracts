// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.26;

import {OPv1Order} from "src/contracts/libraries/OPv1Order.sol";
import {OPv1Trade} from "src/contracts/libraries/OPv1Trade.sol";

library Order {
    using OPv1Order for OPv1Order.Data;
    using OPv1Order for bytes;
    using OPv1Trade for uint256;

    /// Order flags
    struct Flags {
        bytes32 kind;
        bytes32 sellTokenBalance;
        bytes32 buyTokenBalance;
        bool partiallyFillable;
    }

    function toUint256(Flags memory flags) internal pure returns (uint256 encodedFlags) {
        // OPv1Order.KIND_SELL = 0 (default)
        if (flags.kind == OPv1Order.KIND_BUY) {
            encodedFlags |= 1 << 0;
        } else if (flags.kind != OPv1Order.KIND_SELL) {
            revert("Invalid order kind");
        }

        // Partially fillable = 0 (default) - ie. fill-or-kill
        if (flags.partiallyFillable) {
            encodedFlags |= 1 << 1;
        }

        // ERC20 sellTokenBalance = 0 (default; 1 << 2 has the same effect)
        if (flags.sellTokenBalance == OPv1Order.BALANCE_EXTERNAL) {
            encodedFlags |= 2 << 2;
        } else if (flags.sellTokenBalance == OPv1Order.BALANCE_INTERNAL) {
            encodedFlags |= 3 << 2;
        } else if (flags.sellTokenBalance != OPv1Order.BALANCE_ERC20) {
            revert("Invalid sell token balance");
        }

        // ERC20 buyTokenBalance = 0 (default)
        if (flags.buyTokenBalance == OPv1Order.BALANCE_INTERNAL) {
            encodedFlags |= 1 << 4;
        } else if (flags.buyTokenBalance != OPv1Order.BALANCE_ERC20) {
            revert("Invalid buy token balance");
        }
    }

    function toFlags(uint256 encodedFlags) internal pure returns (Flags memory flags) {
        (flags.kind, flags.partiallyFillable, flags.sellTokenBalance, flags.buyTokenBalance,) =
            encodedFlags.extractFlags();
    }

    /// @dev Computes the order UID for an order and the given owner
    function computeOrderUid(OPv1Order.Data memory order, bytes32 domainSeparator, address owner)
        internal
        pure
        returns (bytes memory orderUid)
    {
        orderUid.packOrderUidParams(order.hash(domainSeparator), owner, order.validTo);
    }
}

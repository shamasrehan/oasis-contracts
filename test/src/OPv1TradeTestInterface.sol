// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "src/contracts/libraries/OPv1Order.sol";
import "src/contracts/libraries/OPv1Trade.sol";

contract OPv1TradeTestInterface {
    function extractOrderTest(IERC20[] calldata tokens, OPv1Trade.Data calldata trade)
        external
        pure
        returns (OPv1Order.Data memory order)
    {
        OPv1Trade.extractOrder(trade, tokens, order);
    }

    function extractFlagsTest(uint256 flags)
        external
        pure
        returns (
            bytes32 kind,
            bool partiallyFillable,
            bytes32 sellTokenBalance,
            bytes32 buyTokenBalance,
            OPv1Signing.Scheme signingScheme
        )
    {
        return OPv1Trade.extractFlags(flags);
    }
}

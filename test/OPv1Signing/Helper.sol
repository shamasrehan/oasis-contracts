// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.26;

import {IERC20} from "src/contracts/interfaces/IERC20.sol";
import {OPv1Signing} from "src/contracts/mixins/OPv1Signing.sol";
import {OPv1Order} from "src/contracts/libraries/OPv1Order.sol";
import {OPv1Trade} from "src/contracts/libraries/OPv1Trade.sol";

// solhint-disable func-name-mixedcase
contract Harness is OPv1Signing {
    constructor(bytes32 _domainSeparator) {
        domainSeparator = _domainSeparator;
    }

    function exposed_recoverOrderFromTrade(
        RecoveredOrder memory recoveredOrder,
        IERC20[] calldata tokens,
        OPv1Trade.Data calldata trade
    ) external view {
        recoverOrderFromTrade(recoveredOrder, tokens, trade);
    }

    function exposed_recoverOrderSigner(OPv1Order.Data memory order, Scheme signingScheme, bytes calldata signature)
        external
        view
        returns (bytes32 orderDigest, address owner)
    {
        (orderDigest, owner) = recoverOrderSigner(order, signingScheme, signature);
    }
}

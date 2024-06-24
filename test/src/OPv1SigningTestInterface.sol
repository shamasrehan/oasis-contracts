// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "src/contracts/libraries/OPv1Order.sol";
import "src/contracts/libraries/OPv1Trade.sol";
import "src/contracts/mixins/OPv1Signing.sol";

contract OPv1SigningTestInterface is OPv1Signing {
    function recoverOrderFromTradeTest(IERC20[] calldata tokens, OPv1Trade.Data calldata trade)
        external
        view
        returns (RecoveredOrder memory recoveredOrder)
    {
        recoveredOrder = allocateRecoveredOrder();
        recoverOrderFromTrade(recoveredOrder, tokens, trade);
    }

    function recoverOrderSignerTest(
        OPv1Order.Data memory order,
        OPv1Signing.Scheme signingScheme,
        bytes calldata signature
    ) external view returns (address owner) {
        (, owner) = recoverOrderSigner(order, signingScheme, signature);
    }
}

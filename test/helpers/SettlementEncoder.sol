// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.26;

import {Vm} from "forge-std/Test.sol";

import {OPv1Order, IERC20} from "src/contracts/libraries/OPv1Order.sol";
import {OPv1Trade} from "src/contracts/libraries/OPv1Trade.sol";
import {OPv1Signing} from "src/contracts/mixins/OPv1Signing.sol";
import {OPv1Interaction} from "src/contracts/libraries/OPv1Interaction.sol";
import {OPv1Settlement} from "src/contracts/OPv1Settlement.sol";

import {Sign} from "test/libraries/Sign.sol";
import {Trade} from "test/libraries/Trade.sol";

import {TokenRegistry} from "./TokenRegistry.sol";

contract SettlementEncoder {
    using OPv1Order for OPv1Order.Data;
    using Trade for OPv1Order.Data;
    using Sign for Vm;

    /// The stage an interaction should be executed in
    enum InteractionStage {
        PRE,
        INTRA,
        POST
    }

    /**
     * Order refund data.
     *
     * @dev after the London hardfork (specifically the introduction of EIP-3529)
     * order refunds have become meaningless as the refunded amount is less than the
     * gas cost of triggering the refund. The logic surrounding this feature is kept
     * in order to keep full test coverage and in case the value of a refund will be
     * increased again in the future. However, order refunds should not be used in
     * an actual settlement.
     */
    struct OrderRefunds {
        bytes[] filledAmounts;
        bytes[] preSignatures;
    }

    /// Encoded settlement parameters
    struct EncodedSettlement {
        IERC20[] tokens;
        uint256[] clearingPrices;
        OPv1Trade.Data[] trades;
        OPv1Interaction.Data[][3] interactions;
    }

    error InvalidOrderUidLength();

    OPv1Settlement public settlement;
    TokenRegistry internal tokenRegistry;
    OPv1Trade.Data[] public trades;
    OPv1Interaction.Data[][3] private interactions_;
    OrderRefunds private refunds;

    constructor(OPv1Settlement _settlement, TokenRegistry _tokenRegistry) {
        settlement = _settlement;
        tokenRegistry = (_tokenRegistry == TokenRegistry(address(0)) ? new TokenRegistry() : _tokenRegistry);
    }

    function tokens() public view returns (IERC20[] memory) {
        return tokenRegistry.addresses();
    }

    function interactions() public view returns (OPv1Interaction.Data[][3] memory) {
        OPv1Interaction.Data[] memory r = encodeOrderRefunds();

        // All the order refunds are encoded in the POST interactions so we take some liberty and
        // use a short variable to represent the POST stage.
        uint256 POST = uint256(InteractionStage.POST);
        OPv1Interaction.Data[] memory postInteractions =
            new OPv1Interaction.Data[](interactions_[POST].length + r.length);

        for (uint256 i = 0; i < interactions_[POST].length; i++) {
            postInteractions[i] = interactions_[POST][i];
        }

        for (uint256 i = 0; i < r.length; i++) {
            postInteractions[interactions_[POST].length + i] = r[i];
        }

        return [
            interactions_[uint256(InteractionStage.PRE)],
            interactions_[uint256(InteractionStage.INTRA)],
            postInteractions
        ];
    }

    function encodeTrade(OPv1Order.Data memory order, Sign.Signature memory signature, uint256 executedAmount) public {
        trades.push(order.toTrade(tokenRegistry.addresses(), signature, executedAmount));
    }

    function signEncodeTrade(
        Vm vm,
        Vm.Wallet memory owner,
        OPv1Order.Data memory order,
        OPv1Signing.Scheme signingScheme,
        uint256 executedAmount
    ) public {
        Sign.Signature memory signature = vm.sign(owner, order, signingScheme, settlement.domainSeparator());
        encodeTrade(order, signature, executedAmount);
    }

    function addInteraction(OPv1Interaction.Data memory interaction, InteractionStage stage) public {
        interactions_[uint256(stage)].push(interaction);
    }

    function addOrderRefunds(OrderRefunds memory orderRefunds) public {
        if (orderRefunds.filledAmounts.length > 0) {
            for (uint256 i = 0; i < orderRefunds.filledAmounts.length; i++) {
                bytes memory filledAmount = orderRefunds.filledAmounts[i];
                if (filledAmount.length != OPv1Order.UID_LENGTH) {
                    revert InvalidOrderUidLength();
                }
                refunds.filledAmounts.push(filledAmount);
            }
        }

        if (orderRefunds.preSignatures.length > 0) {
            for (uint256 i = 0; i < orderRefunds.preSignatures.length; i++) {
                bytes memory preSignature = orderRefunds.preSignatures[i];
                if (preSignature.length != OPv1Order.UID_LENGTH) {
                    revert InvalidOrderUidLength();
                }
                refunds.preSignatures.push(preSignature);
            }
        }
    }

    function toEncodedSettlement() public view returns (EncodedSettlement memory) {
        return EncodedSettlement({
            tokens: tokens(),
            clearingPrices: tokenRegistry.clearingPrices(),
            trades: trades,
            interactions: interactions()
        });
    }

    function toEncodedSettlement(OPv1Interaction.Data[] memory setupInteractions)
        public
        pure
        returns (EncodedSettlement memory)
    {
        return EncodedSettlement({
            tokens: new IERC20[](0),
            clearingPrices: new uint256[](0),
            trades: new OPv1Trade.Data[](0),
            interactions: [new OPv1Interaction.Data[](0), setupInteractions, new OPv1Interaction.Data[](0)]
        });
    }

    function encodeOrderRefunds() private view returns (OPv1Interaction.Data[] memory _refunds) {
        uint256 numInteractions =
            (refunds.filledAmounts.length > 0 ? 1 : 0) + (refunds.preSignatures.length > 0 ? 1 : 0);
        _refunds = new OPv1Interaction.Data[](numInteractions);

        uint256 i = 0;
        if (refunds.filledAmounts.length > 0) {
            _refunds[i++] = refundFnEncoder(OPv1Settlement.freeFilledAmountStorage.selector, refunds.filledAmounts);
        }

        if (refunds.preSignatures.length > 0) {
            _refunds[i] = refundFnEncoder(OPv1Settlement.freePreSignatureStorage.selector, refunds.preSignatures);
        }
    }

    function refundFnEncoder(bytes4 fn, bytes[] memory orderUids) private view returns (OPv1Interaction.Data memory) {
        return OPv1Interaction.Data({
            target: address(settlement),
            value: 0,
            callData: abi.encodeWithSelector(fn, orderUids)
        });
    }
}

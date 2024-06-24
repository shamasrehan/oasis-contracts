// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.26;

import {Vm} from "forge-std/Test.sol";

import {OPv1Order} from "src/contracts/libraries/OPv1Order.sol";
import {OPv1Trade} from "src/contracts/libraries/OPv1Trade.sol";
import {OPv1Signing, EIP1271Verifier} from "src/contracts/mixins/OPv1Signing.sol";

import {Bytes} from "./Bytes.sol";

type PreSignSignature is address;

library Sign {
    using OPv1Order for OPv1Order.Data;
    using OPv1Trade for uint256;
    using Bytes for bytes;

    // Copied from OPv1Signing.sol
    uint256 internal constant PRE_SIGNED = uint256(keccak256("OPv1Signing.Scheme.PreSign"));

    struct Signature {
        /// @dev The signing scheme used in this signature
        OPv1Signing.Scheme scheme;
        /// @dev The signature data specific to the signing scheme
        bytes data;
    }

    struct Eip1271Signature {
        address verifier;
        bytes signature;
    }

    /// @dev Encode and sign the order using the provided signing scheme (EIP-712 or EthSign)
    function sign(
        Vm vm,
        Vm.Wallet memory owner,
        OPv1Order.Data memory order,
        OPv1Signing.Scheme scheme,
        bytes32 domainSeparator
    ) internal returns (Signature memory signature) {
        bytes32 hash = order.hash(domainSeparator);
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (scheme == OPv1Signing.Scheme.Eip712) {
            (v, r, s) = vm.sign(owner, hash);
        } else if (scheme == OPv1Signing.Scheme.EthSign) {
            (v, r, s) = vm.sign(owner, toEthSignedMessageHash(hash));
        } else {
            revert(
                "Cannot create a signature for the specified signature scheme, only ECDSA-based schemes are supported"
            );
        }

        signature.data = abi.encodePacked(r, s, v);
        signature.scheme = scheme;
    }

    /// @dev Encode the data used to verify a pre-signed signature
    function preSign(address owner) internal pure returns (Signature memory) {
        return Signature(OPv1Signing.Scheme.PreSign, abi.encodePacked(owner));
    }

    /// @dev Decode the data used to verify a pre-signed signature
    function toPreSignSignature(Signature memory encodedSignature) internal pure returns (PreSignSignature) {
        if (encodedSignature.scheme != OPv1Signing.Scheme.PreSign) {
            revert("Cannot create a signature for the specified signature scheme, only PreSign is supported");
        }

        address owner;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner := shr(96, mload(add(encodedSignature, 0x20)))
        }
        return PreSignSignature.wrap(owner);
    }

    /// @dev Encodes the necessary data required to verify an EIP-1271 signature
    function sign(EIP1271Verifier verifier, bytes memory signature) internal pure returns (Signature memory) {
        return Signature(OPv1Signing.Scheme.Eip1271, abi.encodePacked(verifier, signature));
    }

    /// @dev Decodes the data used to verify an EIP-1271 signature
    function toEip1271Signature(Signature memory encodedSignature) internal pure returns (Eip1271Signature memory) {
        if (encodedSignature.scheme != OPv1Signing.Scheme.Eip1271) {
            revert("Cannot create a signature for the specified signature scheme, only EIP-1271 is supported");
        }

        address verifier;
        uint256 length = encodedSignature.data.length - 20;
        bytes memory signatureData = encodedSignature.data;
        bytes memory signature = signatureData.slice(20, length);

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            verifier := shr(96, mload(add(signatureData, 0x20)))
        }

        return Eip1271Signature(verifier, signature);
    }

    function toUint256(OPv1Signing.Scheme signingScheme) internal pure returns (uint256 encodedFlags) {
        // OPv1Signing.Scheme.EIP712 = 0 (default)
        if (signingScheme == OPv1Signing.Scheme.EthSign) {
            encodedFlags |= 1 << 5;
        } else if (signingScheme == OPv1Signing.Scheme.Eip1271) {
            encodedFlags |= 2 << 5;
        } else if (signingScheme == OPv1Signing.Scheme.PreSign) {
            encodedFlags |= 3 << 5;
        }
    }

    function toSigningScheme(uint256 encodedFlags) internal pure returns (OPv1Signing.Scheme signingScheme) {
        (,,,, signingScheme) = encodedFlags.extractFlags();
    }

    /// @dev Internal helper function for EthSign signatures (non-EIP-712)
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 ethSignDigest) {
        ethSignDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "src/contracts/libraries/OPv1Order.sol";

contract OPv1OrderTestInterface {
    using OPv1Order for OPv1Order.Data;
    using OPv1Order for bytes;

    function typeHashTest() external pure returns (bytes32) {
        return OPv1Order.TYPE_HASH;
    }

    function hashTest(OPv1Order.Data memory order, bytes32 domainSeparator)
        external
        pure
        returns (bytes32 orderDigest)
    {
        orderDigest = order.hash(domainSeparator);
    }

    function packOrderUidParamsTest(uint256 bufferLength, bytes32 orderDigest, address owner, uint32 validTo)
        external
        pure
        returns (bytes memory orderUid)
    {
        orderUid = new bytes(bufferLength);
        orderUid.packOrderUidParams(orderDigest, owner, validTo);
    }

    function extractOrderUidParamsTest(bytes calldata orderUid)
        external
        pure
        returns (bytes32 orderDigest, address owner, uint32 validTo)
    {
        return orderUid.extractOrderUidParams();
    }
}

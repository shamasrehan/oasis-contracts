// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;

import "src/contracts/OPv1AllowListAuthentication.sol";
import "src/contracts/libraries/OPv1EIP1967.sol";

contract OPv1AllowListAuthenticationTestInterface is OPv1AllowListAuthentication {
    constructor(address owner) {
        OPv1EIP1967.setAdmin(owner);
    }
}

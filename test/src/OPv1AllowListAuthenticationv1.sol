// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;

import "src/contracts/OPv1AllowListAuthentication.sol";

contract OPv1AllowListAuthenticationV2 is OPv1AllowListAuthentication {
    function newMethod() external pure returns (uint256) {
        return 1337;
    }
}

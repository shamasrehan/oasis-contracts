// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;

contract NonPayable {
    // solhint-disable-next-line no-empty-blocks, payable-fallback
    fallback() external {}
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "src/contracts/libraries/OPv1Transfer.sol";

contract OPv1TransferTestInterface {
    function fastTransferFromAccountTest(IVault vault, OPv1Transfer.Data calldata transfer, address recipient)
        external
    {
        OPv1Transfer.fastTransferFromAccount(vault, transfer, recipient);
    }

    function transferFromAccountsTest(IVault vault, OPv1Transfer.Data[] calldata transfers, address recipient)
        external
    {
        OPv1Transfer.transferFromAccounts(vault, transfers, recipient);
    }

    function transferToAccountsTest(IVault vault, OPv1Transfer.Data[] memory transfers) external {
        OPv1Transfer.transferToAccounts(vault, transfers);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

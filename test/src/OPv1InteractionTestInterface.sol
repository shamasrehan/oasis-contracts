// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "src/contracts/libraries/OPv1Interaction.sol";

contract OPv1InteractionTestInterface {
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function executeTest(OPv1Interaction.Data calldata interaction) external {
        OPv1Interaction.execute(interaction);
    }

    function selectorTest(OPv1Interaction.Data calldata interaction) external pure returns (bytes4) {
        return OPv1Interaction.selector(interaction);
    }
}

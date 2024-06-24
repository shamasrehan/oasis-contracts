// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;

/// @title Oasis Protocol v1 Authentication Interface
/// @author Oasis Developers
interface OPv1Authentication {
    /// @dev determines whether the provided address is an authenticated solver.
    /// @param prospectiveSolver the address of prospective solver.
    /// @return true when prospectiveSolver is an authenticated solver, otherwise false.
    function isSolver(address prospectiveSolver) external view returns (bool);
}

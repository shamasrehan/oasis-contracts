// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "src/contracts/interfaces/OPv1EIP1271.sol";
import "src/contracts/interfaces/IERC20.sol";
import "src/contracts/libraries/OPv1Order.sol";
import "src/contracts/libraries/OPv1SafeERC20.sol";
import "src/contracts/libraries/SafeMath.sol";
import "src/contracts/OPv1Settlement.sol";

/// @title Proof of Concept Smart Order
/// @author Oasis Developers
contract SmartSellOrder is EIP1271Verifier {
    using OPv1Order for OPv1Order.Data;
    using OPv1SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant APPDATA = keccak256("SmartSellOrder");

    address public immutable owner;
    bytes32 public immutable domainSeparator;
    IERC20 public immutable sellToken;
    IERC20 public immutable buyToken;
    uint256 public immutable totalSellAmount;
    uint256 public immutable totalFeeAmount;
    uint32 public immutable validTo;

    constructor(
        OPv1Settlement settlement,
        IERC20 sellToken_,
        IERC20 buyToken_,
        uint32 validTo_,
        uint256 totalSellAmount_,
        uint256 totalFeeAmount_
    ) {
        owner = msg.sender;
        domainSeparator = settlement.domainSeparator();
        sellToken = sellToken_;
        buyToken = buyToken_;
        validTo = validTo_;
        totalSellAmount = totalSellAmount_;
        totalFeeAmount = totalFeeAmount_;

        sellToken_.approve(address(settlement.vaultRelayer()), type(uint256).max);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function withdraw(uint256 amount) external onlyOwner {
        sellToken.safeTransfer(owner, amount);
    }

    function close() external onlyOwner {
        uint256 balance = sellToken.balanceOf(address(this));
        if (balance != 0) {
            sellToken.safeTransfer(owner, balance);
        }
        selfdestruct(payable(owner));
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4 magicValue)
    {
        uint256 sellAmount = abi.decode(signature, (uint256));
        OPv1Order.Data memory order = orderForSellAmount(sellAmount);

        if (order.hash(domainSeparator) == hash) {
            magicValue = OPv1EIP1271.MAGICVALUE;
        }
    }

    function orderForSellAmount(uint256 sellAmount) public view returns (OPv1Order.Data memory order) {
        order.sellToken = sellToken;
        order.buyToken = buyToken;
        order.receiver = owner;
        order.sellAmount = sellAmount;
        order.buyAmount = buyAmountForSellAmount(sellAmount);
        order.validTo = validTo;
        order.appData = APPDATA;
        order.feeAmount = totalFeeAmount.mul(sellAmount).div(totalSellAmount);
        order.kind = OPv1Order.KIND_SELL;
        // NOTE: We counter-intuitively set `partiallyFillable` to `false`, even
        // if the smart order as a whole acts like a partially fillable order.
        // This is done since, once a settlement commits to a specific sell
        // amount, then it is expected to use it completely and not partially.
        order.partiallyFillable = false;
        order.sellTokenBalance = OPv1Order.BALANCE_ERC20;
        order.buyTokenBalance = OPv1Order.BALANCE_ERC20;
    }

    function buyAmountForSellAmount(uint256 sellAmount) private view returns (uint256 buyAmount) {
        uint256 feeAdjustedBalance =
            sellToken.balanceOf(address(this)).mul(totalSellAmount).div(totalSellAmount.add(totalFeeAmount));
        uint256 soldAmount = totalSellAmount > feeAdjustedBalance ? totalSellAmount - feeAdjustedBalance : 0;

        // NOTE: This is currently a silly price strategy where the xrate
        // increases linearly from 1:1 to 1:2 as the smart order gets filled.
        // This can be extended to more complex "price curves".
        buyAmount = sellAmount.mul(totalSellAmount.add(sellAmount).add(soldAmount)).div(totalSellAmount);
    }
}

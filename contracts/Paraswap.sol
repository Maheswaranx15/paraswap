// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from './IERC20.sol';

import { IBaseSwap } from './IBaseSwap.sol';
import { IAugustusSwapper } from './IAugustusSwapper.sol';

import { UniversalERC20 } from './UniversalERC20.sol';

contract ParaSwapConnector is IBaseSwap {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    /**
     * @dev Connector name
     */
    string public constant NAME = 'ParaSwap';

    /**
     * @dev Paraswap Router Address
     */
    address internal constant PARASWAP_ROUTER = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);


    /* ============ Events ============ */

    /**
     * @dev Emitted when the sender swap tokens.
     * @param account Address who create operation.
     * @param fromToken The address of the token to sell.
     * @param toToken The address of the token to buy.
     * @param amount The amount of the token to sell.
     */
    event LogExchange(address indexed account, address toToken, address fromToken, uint256 amount);

    /* ============ External Functions ============ */

    /**
     * @dev Swap ETH/ERC20_Token using ParaSwap.
     * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
     * @param _toToken The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _fromToken The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to sell.
     * @param _callData Data from ParaSwap API.
     * @return buyAmount Returns the amount of tokens received.
     */
    
    function swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) external payable returns (uint256 buyAmount) {
        buyAmount = _swap(_toToken, _fromToken, _amount, _callData);
        emit LogExchange(msg.sender, _toToken, _fromToken, _amount);
    }

    /* ============ Internal Functions ============ */

     function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    /**
     * @dev Universal approve tokens to paraswap router and execute calldata.
     * @param _toToken The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _fromToken The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to sell.
     * @param _callData Data from ParaSwap API.
     * @return buyAmount Returns the amount of tokens received.
     */
    function _swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) internal returns (uint256 buyAmount) {
        address tokenProxy = IAugustusSwapper(PARASWAP_ROUTER).getTokenTransferProxy();
        IERC20(_fromToken).approve(tokenProxy, _amount);
        uint256 value = (_fromToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeE) ? _amount : 0);
        uint256 initalBalalance = IERC20(_toToken).balanceOf(address(this));

        (bool success, bytes memory results) = PARASWAP_ROUTER.call{ value: value }(_callData);

        if (!success) {
            revert(string(results));
        }

        uint256 finalBalalance = IERC20(_toToken).balanceOf(address(this));

        buyAmount = finalBalalance - initalBalalance;
    } 
}

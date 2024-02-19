// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IAugustusSwapper.sol";
import "./IParaswap.sol";
import "./lib/Utils.sol";

contract ParaswapIntegration {
    IAugustusSwapper augustusSwapperContract;
    IParaswap paraswapContract;

    constructor(address _augustusSwapperAddress, address _paraswapAddress) {
        augustusSwapperContract = IAugustusSwapper(_augustusSwapperAddress);
        paraswapContract = IParaswap(_paraswapAddress);
    }

    function swap(Utils.SellData calldata data) external {
        uint256 receivedAmount = paraswapContract.multiSwap(data);
        augustusSwapperContract.transferTokens(data.destToken, recipient, receivedAmount);

    }
}

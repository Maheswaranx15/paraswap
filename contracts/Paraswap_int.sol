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

   function swap(Utils.SimpleData calldata _data) external nonReentrant {
        require(_data.beneficiary == msg.sender, "beneficiary != msg.sender");
        require(
            tokens[_data.fromToken][_data.beneficiary] >= _data.fromAmount,
            "Balance insufficient");
        require(_data.fromToken == BTCT_ADDR,"fromToken != BTCT_ADDR");
        tokens[_data.fromToken][_data.beneficiary] = tokens[_data.fromToken][
            _data.beneficiary
        ].sub(_data.fromAmount);
        
        _doSimpleSwap(_data); //no received amount, tokens to go user's wallet
    }

    /// @dev _doSimpleSwap - performs paraswap transaction - BALANCE & TOKEN CHECKS MUST OCCUR BEFORE CALLING THIS
    /// @param _data data from API call that is ready to be sent to paraswap interface
    function _doSimpleSwap(Utils.SimpleData calldata _data) internal {
        //address proxy = IAugustusSwapper(paraswapAddress).getTokenTransferProxy();

        IERC20(_data.fromToken).safeIncreaseAllowance(
            IAugustusSwapper(paraswapAddress).getTokenTransferProxy(), 
            _data.fromAmount
        );

        IParaswap(paraswapAddress).simpleSwap(_data);
    }


}



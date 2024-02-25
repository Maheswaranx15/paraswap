//0x0e0588e725a1A57074a97a4aA2553EF0AfbCfd44
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAugustusSwapper.sol";
import "./IParaswap.sol";
import "./lib/Utils.sol";
import "./SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ParaswapIntegration {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IAugustusSwapper augustusSwapperContract;
    IParaswap paraswapContract;
    address public BTCT_ADDR;
    mapping(address => mapping(address => uint256)) public tokens;
    address public paraswapAddress;

    constructor(address _augustusSwapperAddress, address _paraswapAddress) {
        augustusSwapperContract = IAugustusSwapper(_augustusSwapperAddress);
        paraswapContract = IParaswap(_paraswapAddress);
        paraswapAddress = _paraswapAddress;
    }

   function swap(Utils.SellData calldata _data) external nonReentrant {
        require(_data.beneficiary == msg.sender, "beneficiary != msg.sender");
        require(
            tokens[_data.fromToken][_data.beneficiary] >= _data.fromAmount,
            "Balance insufficient");
        require(_data.fromToken == BTCT_ADDR,"fromToken != BTCT_ADDR");
        tokens[_data.fromToken][_data.beneficiary] = tokens[_data.fromToken][
            _data.beneficiary
        ].sub(_data.fromAmount);
        
        _doSimpleSwap(_data); 
    }

    /// @dev _doSimpleSwap - performs paraswap transaction - BALANCE & TOKEN CHECKS MUST OCCUR BEFORE CALLING THIS
    /// @param _data data from API call that is ready to be sent to paraswap interface
    function _doSimpleSwap(Utils.SellData calldata _data) internal {
        //address proxy = IAugustusSwapper(paraswapAddress).getTokenTransferProxy();

        IERC20(_data.fromToken).safeIncreaseAllowance(
            IAugustusSwapper(paraswapAddress).getTokenTransferProxy(), 
            _data.fromAmount
        );

        IParaswap(paraswapAddress).simpleSwap(_data);
    }


}


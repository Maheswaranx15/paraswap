// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

// A partial ERC20 interface.
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;
}

// Demo contract that swaps its ERC20 balance for another ERC20.
// NOT to be used in production.
contract SimpleTokenSwap {

    event BoughtTokens(IERC20 sellToken, IERC20 buyToken, uint256 boughtAmount);
    address public owner;
    // 0x ExchangeProxy address.
    // See https://docs.0x.org/developer-resources/contract-addresses
    address public exchangeProxy;

    constructor(address _exchangeProxy) {
        exchangeProxy = _exchangeProxy;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    receive() external payable {}

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawToken(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        require(token.transfer(msg.sender, amount));
    }

    // Transfer ETH held by this contrat to the sender/owner.
    function withdrawETH(uint256 amount)
        external
        onlyOwner
    {
        msg.sender.transfer(amount);
    }

    function fillQuote(
        // The `sellTokenAddress` field from the API response.
        IERC20 sellToken,
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken,
        // The `allowanceTarget` field from the API response.
        address spender,
        // The `to` field from the API response.
        address payable swapTarget,
        // The `data` field from the API response.
        bytes calldata swapCallData
    )
        external
    {
        require(swapTarget == exchangeProxy, "Target not ExchangeProxy");
        require(sellToken.approve(spender, uint256(-1)));
        (bool success,) = swapTarget.call(swapCallData);
        require(success, 'SWAP_CALL_FAILED');

    }
}
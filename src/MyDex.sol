// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDex} from "./interface/IDex.sol";
import {IUniswapV2Factory} from "./interface/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "./interface/IUniswapV2Router.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyDex is IDex {
    IUniswapV2Factory public immutable factory;
    IUniswapV2Router public immutable router;
    address public immutable weth;

    constructor(address _factory, address _router) {
        factory = IUniswapV2Factory(_factory);
        router = IUniswapV2Router(_router);
        weth = router.WETH();
    }

    function sellETH(address buyToken,uint256 minBuyAmount) external payable returns (uint[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = buyToken;
        uint256 amount = IERC20(buyToken).balanceOf(msg.sender);
        amounts = router.swapExactETHForTokens{value: msg.value}(minBuyAmount, path, msg.sender, block.timestamp);
        // 不能盲目相信第三方合约，需要自行判断
        require(IERC20(buyToken).balanceOf(msg.sender) >= amount + minBuyAmount);
    }

    function buyETH(address sellToken,uint256 sellAmount,uint256 minBuyAmount) external returns (uint[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = weth;
        // 将token先转入dex合约，并授权给router合约
        require(IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount), "dex: transfer sellToken error");
        require(IERC20(sellToken).approve(address(router), sellAmount), "dex: approve sellToken error");
        uint256 amount = payable(msg.sender).balance;
        amounts = router.swapExactTokensForETH(sellAmount, minBuyAmount, path, msg.sender, block.timestamp);
        // 不能盲目相信第三方合约，需要自行判断
        require(payable(msg.sender).balance >= amount + minBuyAmount, "dex: swap failed");
    }

}

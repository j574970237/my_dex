// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDex} from "./interface/IDex.sol";
import {IUniswapV2Factory} from "./interface/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "./interface/IUniswapV2Router.sol";
import {WETH} from "./WETH9.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyDex is IDex {
    IUniswapV2Factory public factory;
    IUniswapV2Router public router;
    WETH public weth;

    constructor(address _factory, address _router, address _weth) {
        factory = IUniswapV2Factory(_factory);
        router = IUniswapV2Router(_router);
        weth = WETH(payable(_weth));
    }

    function sellETH(address buyToken,uint256 minBuyAmount) external payable returns (uint[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = buyToken;
        return router.swapExactETHForTokens{value: msg.value}(minBuyAmount, path, msg.sender, block.timestamp + 300);
    }

    function buyETH(address sellToken,uint256 sellAmount,uint256 minBuyAmount) external returns (uint[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = address(weth);
        // 将token先转入dex合约，并授权给router合约
        require(IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount), "dex: transfer sellToken error");
        require(IERC20(sellToken).approve(address(router), sellAmount), "dex: approve sellToken error");
        return router.swapExactTokensForETH(sellAmount, minBuyAmount, path, msg.sender, block.timestamp + 300);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './interface/IUniswapV2Callee.sol';
import './libraries/UniswapV2Library.sol';

import './interface/IUniswapV2Router02.sol';
import './interface/IERC20.sol';
import './interface/IWETH.sol';


contract MyFlashSwap is IUniswapV2Callee {
    
    address immutable factory;
    address immutable router2;
    address immutable owner;

    constructor(address _factory, address _router2) {
        factory = _factory;
        router2 = _router2;
        owner = msg.sender;
    }


    // pair1  1 JJT = 1000 RNT,  pair2 1.5 JJT  =  1000 RNT  
    // 从 pair1 借出来 1000 个 RNT, 在pair2兑换 1.5 JJT， 还回 1 个 JJT 给 pair1
    function flashSwap(address pair, address borrowToken, uint256 borrowAmount) external {
        address token0 = IUniswapV2Pair(pair).token0();
        
        if(token0 == borrowToken) {
            IUniswapV2Pair(pair).swap(borrowAmount, 0, address(this), new bytes(0x01));
        } else {
            IUniswapV2Pair(pair).swap(0, borrowAmount, address(this), new bytes(0x01));
        }
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        require(amount0 == 0 || amount1 == 0, "invalid amounts"); // this strategy is unidirectional
        
        // msg.sender is pair1 
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1), "invalid caller"); // ensure that msg.sender is actually a V2 pair

        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        address[] memory path = new address[](2);
        uint amountRequired;

        // 收到了 token0,  兑换为 token1
        if (balance0 > 0) {

            path[0] = token1;
            path[1] = token0;
            amountRequired = UniswapV2Library.getAmountsIn(factory, balance0, path)[0];
            
            IERC20(token0).approve(router2, type(uint256).max);

            path[0] = token0;
            path[1] = token1;
            uint[] memory amounts = IUniswapV2Router02(router2).swapExactTokensForTokens(balance0, 0, path, address(this), block.timestamp);

            uint amountReceived = amounts[1];

            require(amountReceived > amountRequired, "unprofitable 1");

            assert(IERC20(token1).transfer(msg.sender, amountRequired)); // return token1 to V2 pair

            IERC20(token1).transfer(owner, amountReceived - amountRequired); // keep the rest! (tokens)
        }

        // 收到了 token1, 兑换为 token0
        if (balance1 > 0) {

            path[0] = token0;
            path[1] = token1;
            amountRequired = UniswapV2Library.getAmountsIn(factory, balance1, path)[0];


            path[0] = token1;
            path[1] = token0;
            IERC20(token1).approve(router2, type(uint256).max);
            uint[] memory amounts = IUniswapV2Router02(router2).swapExactTokensForTokens(balance1, 0, path, address(this), block.timestamp);
            uint amountReceived = amounts[1];

            require(amountReceived > amountRequired, "unprofitable");
            require(IERC20(token0).transfer(msg.sender, amountRequired)); // return token0 to V2 pair

            IERC20(token0).transfer(owner, amountReceived - amountRequired); // keep the rest! (tokens)
        }

    }
}
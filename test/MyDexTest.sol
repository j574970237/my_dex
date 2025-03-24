// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IDex} from "../src/interface/IDex.sol";
import {IUniswapV2Factory} from "../src/interface/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";
import {IUniswapV2Pair} from "../src/interface/IUniswapV2Pair.sol";
import {WETH} from "../src/WETH9.sol";
import {RNT} from "../src/RNT.sol";
import {MyDex} from "../src/MyDex.sol";

contract MyDexTest is Test {
    IUniswapV2Factory public factory;
    IUniswapV2Router public router;
    WETH public weth;
    address public owner;
    RNT public rnt;
    MyDex public dex;

    function setUp() public {
        // 设置为本地测试网
        vm.createSelectFork("http://127.0.0.1:8545");
        owner = makeAddr("Owner");
        // 本地测试网的各合约地址
        factory = IUniswapV2Factory(0x27f7785b17c6B4d034094a1B16Bc928bD697f386);
        router = IUniswapV2Router(0x17f4B55A352Be71CC03856765Ad04147119Aa09B);
        rnt = RNT(0x08677Af0A7F54fE2a190bb1F75DE682fe596317e);
        weth = WETH(payable(0x1E53bea57Dd5dDa7bFf1a1180a2f64a5c9e222f5));
        vm.prank(owner);
        dex = new MyDex(address(factory), address(router));
    }

    /**
    测试步骤：
    1.创建RNT-ETH交易对
    2.添加初始化流动性
    3.移除流动性
    4.使用 RNT兑换 ETH
    5.用 ETH兑换RNT
     */
    function testMyDex() public {
        address alice = makeAddr("Alice");
        vm.deal(alice, 10 ether);
        deal(address(rnt), alice, 100000 * 1e18);
        // 1.创建RNT-ETH交易对
        address pair = factory.createPair(address(rnt), address(weth));
        assert(pair != address(0));
        console.log("pair address:", pair);

        // 2.添加初始化流动性
        vm.startPrank(alice);
        // 授权给router合约
        rnt.approve(address(router), 100000 * 1e18);
        (uint256 amountToken1, uint256 amountETH1, uint256 liquidity1) = router.addLiquidityETH{value: 1 ether}(address(rnt), 10000 * 1e18, 5000 * 1e18, 0.5 ether, alice, block.timestamp + 300);
        assert(amountToken1 > 5000 * 1e18);
        assertEq(rnt.balanceOf(alice), 100000 * 1e18 - amountToken1);
        assertEq(alice.balance, 10 ether - amountETH1);
        assert(liquidity1 > 0);

        // 再添加一次，用于移除流动性测试
        (uint256 amountToken2, uint256 amountETH2, uint256 liquidity2) = router.addLiquidityETH{value: 1 ether}(address(rnt), 10000 * 1e18, 5000 * 1e18, 0.5 ether, alice, block.timestamp + 300);
        IUniswapV2Pair(pair).approve(address(router), liquidity2);
        (uint256 amountToken3, uint256 amountETH3) = router.removeLiquidityETH(address(rnt), liquidity2, 5000 * 1e18, 0.5 ether, alice, block.timestamp + 300);
        assert(amountToken3 > 8000 * 1e18);
        assert(amountETH3 > 0.8 ether);

        // 4.使用 RNT兑换 ETH
        rnt.approve(address(dex), 100000 * 1e18);
        uint[] memory amounts1 = dex.buyETH(address(rnt), 10000 * 1e18, 0.1 ether);
        assertEq(rnt.balanceOf(alice), 100000 * 1e18 - amountToken1 - amountToken2 + amountToken3 - amounts1[0]);
        assertEq(alice.balance, 10 ether - amountETH1 - amountETH2 + amountETH3 + amounts1[1]);

        // 5.用 ETH兑换RNT
        uint[] memory amounts2 = dex.sellETH{value: 1 ether}(address(rnt), 1000 * 1e18);
        assertEq(rnt.balanceOf(alice), 100000 * 1e18 - amountToken1 - amountToken2 + amountToken3 - amounts1[0] + amounts2[1]);
        assertEq(alice.balance, 10 ether - amountETH1 - amountETH2 + amountETH3 + amounts1[1] - amounts2[0]);

        vm.stopPrank();
    }
}
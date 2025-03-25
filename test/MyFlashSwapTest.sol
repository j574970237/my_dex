// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IUniswapV2Factory} from "../src/interface/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";
import {IUniswapV2Pair} from "../src/interface/IUniswapV2Pair.sol";
import {RNT} from "../src/RNT.sol";
import {JJToken} from "../src/JJToken.sol";
import {MyFlashSwap} from "../src/MyFlashSwap.sol";

contract MyFlashSwapTest is Test {
    IUniswapV2Factory public factory;
    IUniswapV2Router public router;
    IUniswapV2Factory public factory2;
    IUniswapV2Router public router2;
    address public owner;
    RNT public rnt;
    JJToken public jjt;
    MyFlashSwap public flashSwap;

    function setUp() public {
        // 设置为本地测试网
        vm.createSelectFork("http://127.0.0.1:8545");
        // 测试合约部署者
        owner = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        // 本地测试网的各合约地址
        factory = IUniswapV2Factory(0x63275D081C4A77AE69f76c4952F9747a5559a519);
        router = IUniswapV2Router(0x5A61c51C6745b3F509f4a1BF54BFD04e04aF430a);
        factory2 = IUniswapV2Factory(0x832092FDF1D32A3A1b196270590fB0E25DF129FF);
        router2 = IUniswapV2Router(0xe3e4631D734e4b3F900AfcC396440641Ed0df339);
        rnt = RNT(0x67832b9Fc47eb3CdBF7275b95a29740EC58193D2);
        jjt = JJToken(0x8729c0238b265BaCF6fE397E8309897BB5c40473);
    }

    /**
    测试步骤：
    1.在两个池子中分别创建JJT-RNT交易对, 并添加初始化流动性（价值不同）
    2.Alice执行闪电兑换完成套利
     */
    function testMyFlashSwap() public {
        vm.startPrank(owner);
        // 1.PoolA 创建JJT-RNT交易对
        address pair1 = address(0xb76C3F6a78914e5B1FcB9922297f51016C3787dB);
        console.log("pair1 address: ", pair1);
        jjt.approve(address(router), type(uint256).max);
        rnt.approve(address(router), type(uint256).max);
        // 添加流动性，1 JJT = 1000 RNT
        (uint256 amountJJT1, uint256 amountRNT1, uint256 liquidity1) = router.addLiquidity(address(jjt), address(rnt), 10 * 1e18, 10000 * 1e18, 5 * 1e18, 5000 * 1e18, owner, block.timestamp + 300);
        assert(liquidity1 > 0);
        // PoolB 创建JJT-RNT交易对
        address pair2 = factory2.createPair(address(jjt), address(rnt));
        assert(pair2 != address(0));
        console.log("pair2 address: ", pair2);
        jjt.approve(address(router2), type(uint256).max);
        rnt.approve(address(router2), type(uint256).max);
        // 添加流动性，1.5 JJT = 1000 RNT
        (uint256 amountJJT2, uint256 amountRNT2, uint256 liquidity2) = router2.addLiquidity(address(jjt), address(rnt), 15 * 1e18, 10000 * 1e18, 7 * 1e18, 5000 * 1e18, owner, block.timestamp + 300);
        assert(liquidity2 > 0);
        vm.stopPrank();
        
        // 2. Alice执行闪电兑换完成套利
        address alice = makeAddr("Alice");
        // vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        flashSwap = new MyFlashSwap(address(factory), address(router2));
        console.log("before swap, alice's jjt balance: ", jjt.balanceOf(alice));
        console.log("start flash swap...");
        // 从 pair1 借出来 1000 个 RNT, 在pair2兑换 1.5 JJT， 还回 1 个 JJT 给 pair1
        flashSwap.flashSwap(pair1, address(rnt), 1000 * 1e18);
        console.log("finish flash swap...");
        console.log("after swap, alice's jjt balance: ", jjt.balanceOf(alice));
    }
}
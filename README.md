# My Dex

## 项目简介

本项目实现了一个简易版本的dex，包括如下功能：

1. 卖出ETH，兑换成 buyToken；

2. 买入ETH，用 sellToken 兑换。

## 注意事项

1. 在本地测试网测试时，直接调用`UniswapV2Factory`的`addLiquidityETH`函数会出现问题，我们需要在`v2-core/contracts/UniswapV2Factory.sol`源码中添加下列代码：

```solidity
bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));
```

这样部署后我们就可以通过合约调用得到一个`INIT_CODE_PAIR_HASH`，这在部署`UniswapV2Router02`会用到。

2. 下面我们需要部署`UniswapV2Router02`，先打开`v2-periphery/contracts/libraries/UniswapV2Library.sol`，找到`pairFor`函数，其中有一行注释`// init code hash`,这个hash值只兼容以太坊主网和sepolia测试网，我们部署到自己网络时，需要修改成我们上面得到的`INIT_CODE_PAIR_HASH`，**注意需要去除"0x"前缀再填入。** 这样部署后的合约就可以正常添加流动性了。

## 测试步骤

首先通过foundry的anvil指令部署本地测试网。

```shell
anvil --fork-url https://ethereum-rpc.publicnode.com
```

我们取第一个用户的地址和私钥来部署合约。

deployer地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

### 设置环境变量

```shell
# 换成测试网用户对应的私钥
export PRIVATE_KEY=0xac0974be......f2ff80
```

```shell
export RPC_URL=http://localhost:8545
```

### 进入`src`目录部署WETH

```shell
forge create WETH --private-key $PRIVATE_KEY --rpc-url $RPC_URL --broadcast
```

WETH地址: 0x1E53bea57Dd5dDa7bFf1a1180a2f64a5c9e222f5

### 部署UniswapV2Factory

部署细节详见**注意事项**。

```shell
forge create lib/v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory --private-key $PRIVATE_KEY --rpc-url $RPC_URL --broadcast --constructor-args "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
```

UniswapV2Factory地址: 0x27f7785b17c6B4d034094a1B16Bc928bD697f386

### 部署UniswapV2Router02

部署细节详见**注意事项**。

```shell
forge create lib/v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 --private-key $PRIVATE_KEY --rpc-url $RPC_URL --broadcast --constructor-args "0x27f7785b17c6B4d034094a1B16Bc928bD697f386" "0x1E53bea57Dd5dDa7bFf1a1180a2f64a5c9e222f5"
```

UniswapV2Router02地址: 0x17f4B55A352Be71CC03856765Ad04147119Aa09B

### 部署RNT

```shell
forge create RNT --private-key $PRIVATE_KEY --rpc-url $RPC_URL --broadcast 
```

RNT地址: 0x08677Af0A7F54fE2a190bb1F75DE682fe596317e

### 运行测试合约

进入`test`文件夹，找到`MyDexTest.sol`合约的`setUp()`函数，修改函数内的各合约地址，然后输入测试指令：

```shell
forge test --mc MyDexTest -vvv
```

测试成功结果如下：

```log
[⠊] Compiling...
[⠘] Compiling 1 files with Solc 0.8.28
[⠃] Solc 0.8.28 finished in 1.78s
Compiler run successful!

Ran 1 test for test/MyDexTest.sol:MyDexTest
[PASS] testMyDex() (gas: 2663434)
Logs:
  pair address: 0x0D9153e0841C11c4E1E75B129F59b8800f5263bf

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 6.31ms (1.74ms CPU time)

Ran 1 test suite in 105.70ms (6.31ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```



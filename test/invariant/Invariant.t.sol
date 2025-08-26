// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { PoolFactory } from "src/PoolFactory.sol";
import { TSwapPool } from "src/TSwapPool.sol";
import { Handler } from "./Handler.t.sol";

contract InvariantTest is StdInvariant, Test {
    ERC20Mock public poolToken;
    ERC20Mock public weth;

    PoolFactory public factory;
    TSwapPool public pool;

    Handler public handler;

    int256 constant STARTING_X = 100e18;
    int256 constant STARTING_Y = 50e18;

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = new TSwapPool(address(poolToken), address(weth), "T-Swap Mock", "tsMOCK");

        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(uint256(STARTING_Y), uint256(STARTING_Y), uint256(STARTING_X), uint64(block.timestamp));

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;
        selectors[1] = handler.deposit.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    function statefulFuzz_constantProductFormulaStaysSame() public view {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {HookTest} from "./utils/HookTest.sol";
import {KeyringGuardedPool} from "../src/KeyringGuardedPool.sol";
import {KeyringGuardedPoolImplementation} from "./implementation/KeyringGuardedPoolImplementation.sol";

contract KeyringGuardedPoolTest is HookTest, Deployers, GasSnapshot {
    using PoolIdLibrary for IPoolManager.PoolKey;
    using CurrencyLibrary for Currency;

    address public constant USER_OK = address(uint160(uint256(keccak256(abi.encodePacked("USER_OK")))));
    address public constant USER_NOT = address(uint160(uint256(keccak256(abi.encodePacked("USER_NO")))));
    address public constant keyringGuard = address(0);
    KeyringGuardedPool public constant kgp = KeyringGuardedPool(address(uint160(Hooks.AFTER_SWAP_FLAG)));
    
    IPoolManager.PoolKey public poolKey;
    PoolId public poolId;

    constructor() {
        uint256 forkId = vm.createFork(vm.envString("FORK_URL"), 116_399_431);
        vm.selectFork(forkId);

        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        // testing environment requires our contract to override `validateHookAddress`
        // well do that via the Implementation contract to avoid deploying the override with the production contract
        KeyringGuardedPoolImplementation impl = new KeyringGuardedPoolImplementation(manager, kgp, keyringGuard);
        etchHook(address(impl), address(kgp));

        // Create the pool
        poolKey =
            IPoolManager.PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(kgp));
        poolId = poolKey.toId();
        manager.initialize(poolKey, SQRT_RATIO_1_1);

        // Provide liquidity to the pool
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-60, 60, 10 ether));
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-120, 120, 10 ether));
        modifyPositionRouter.modifyPosition(
            poolKey, IPoolManager.ModifyPositionParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether)
        );
    }

    function setUp() public {
        vm.deal(USER_OK, 1 ether);
        vm.deal(USER_NOT, 1 ether);
    }

    function testKeyringHook() public {
        // Perform a test swap //
        int256 amount = 100;
        bool zeroForOne = true;

        vm.prank(USER_NOT);
        vm.expectRevert();
        swap(poolKey, amount, zeroForOne);

        vm.prank(USER_OK);
        swap(poolKey, amount, zeroForOne);
    }
}

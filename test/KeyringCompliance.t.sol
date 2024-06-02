// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {GetSender} from "./shared/GetSender.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {KeyringCompliance} from "../contracts/hooks/examples/KeyringCompliance.sol";
import {KeyringComplianceImplementation} from "./shared/implementation/KeyringComplianceImplementation.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {TestERC20} from "@uniswap/v4-core/src/test/TestERC20.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {HookEnabledSwapRouter} from "./utils/HookEnabledSwapRouter.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MockKeyringCache} from "./mocks/MockKeyringCache.sol";

contract TestKeyringCompliance is Test, Deployers {
    uint256 constant MAX_DEADLINE = 12329839823;
    int24 constant TICK_SPACING = 60;

    HookEnabledSwapRouter router;
    TestERC20 token0;
    TestERC20 token1;
    MockKeyringCache keyring = new MockKeyringCache();
    KeyringComplianceImplementation keyringComplianceImpl =
        KeyringComplianceImplementation(address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG)));
    uint32 policyId = 1;

    function setUp() public {
        deployFreshManagerAndRouters();
        (currency0, currency1) = deployMintAndApprove2Currencies();

        router = new HookEnabledSwapRouter(manager);
        token0 = TestERC20(Currency.unwrap(currency0));
        token1 = TestERC20(Currency.unwrap(currency1));

        vm.record();
        KeyringComplianceImplementation impl =
            new KeyringComplianceImplementation(manager, address(keyring), policyId, keyringComplianceImpl);
        (, bytes32[] memory writes) = vm.accesses(address(impl));
        vm.etch(address(keyringComplianceImpl), address(impl).code);
        // for each storage key that was written during the hook implementation, copy the value over
        unchecked {
            for (uint256 i = 0; i < writes.length; i++) {
                bytes32 slot = writes[i];
                vm.store(address(keyringComplianceImpl), slot, vm.load(address(impl), slot));
            }
        }

        token0.approve(address(keyringComplianceImpl), type(uint256).max);
        token1.approve(address(keyringComplianceImpl), type(uint256).max);
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);
    }

    function createPoolKey(TestERC20 tokenA, TestERC20 tokenB) internal view returns (PoolKey memory) {
        if (address(tokenA) > address(tokenB)) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey(
            Currency.wrap(address(tokenA)), Currency.wrap(address(tokenB)), 3000, TICK_SPACING, keyringComplianceImpl
        );
    }

    function test_KeyringCompliance() public {
        key = createPoolKey(token0, token1);
        key.tickSpacing = 30;
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
        initPool(key.currency0, key.currency1, keyringComplianceImpl, 3000, SQRT_PRICE_1_1, ZERO_BYTES);

        vm.startPrank(DEFAULT_SENDER);

        // unauthorized user
        vm.expectRevert(KeyringCompliance.Unauthorized.selector);
        router.swap(
            key,
            IPoolManager.SwapParams(false, -1 ether, SQRT_PRICE_1_1 + 1),
            HookEnabledSwapRouter.TestSettings(false, false),
            ZERO_BYTES
        );

        // authorized user
        keyring.setCredential(DEFAULT_SENDER, policyId, true);
        vm.expectRevert(HookEnabledSwapRouter.NoSwapOccurred.selector);
        router.swap(
            key,
            IPoolManager.SwapParams(false, -1 ether, SQRT_PRICE_1_1 + 1),
            HookEnabledSwapRouter.TestSettings(false, false),
            ZERO_BYTES
        );

        vm.stopPrank();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {IKeyringGuard} from "./interfaces/IKeyringGuard.sol";

/// @title A Keyring-guarded Uniswap V4 pool
/// @dev This contract overrides entry hooks of the pool lifecycle to stop unauthorized swaps
contract KeyringGuardedPool is BaseHook {
    using PoolIdLibrary for IPoolManager.PoolKey;

    IKeyringGuard public immutable keyringGuard;

    constructor(IPoolManager _poolManager, address _keyringGuard) BaseHook(_poolManager) {
        assert(_keyringGuard != address(0));

        keyringGuard = IKeyringGuard(_keyringGuard);
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: false,
            beforeModifyPosition: false, // TODO: TRUE prevent position retracing
            afterModifyPosition: false,
            beforeSwap: true, // prevent swaps
            afterSwap: false,
            beforeDonate: false, // prevent unguarded transfers
            afterDonate: false
        });
    }

    function beforeSwap(address, IPoolManager.PoolKey calldata, IPoolManager.SwapParams calldata)
        external
        override
        returns (bytes4)
    {
        if (!keyringGuard.isAuthorized(address(this), msg.sender)) revert("Unauthorized user");

        return BaseHook.beforeSwap.selector;
    }
}

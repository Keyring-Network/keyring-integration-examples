// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {KeyringGuardedPool} from "../../src/KeyringGuardedPool.sol";

contract KeyringGuardedPoolImplementation is KeyringGuardedPool {
    constructor(IPoolManager poolManager, KeyringGuardedPool addressToEtch, address keyringGuard)
        KeyringGuardedPool(poolManager, keyringGuard)
    {
        Hooks.validateHookAddress(addressToEtch, getHooksCalls());
    }

    // make this a no-op in testing
    function validateHookAddress(BaseHook _this) internal pure override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseHook} from "../../../contracts/BaseHook.sol";
import {KeyringCompliance} from "../../../contracts/hooks/examples/KeyringCompliance.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

contract KeyringComplianceImplementation is KeyringCompliance {
    uint32 public time;

    constructor(IPoolManager _poolManager, address _keyring, uint32 _policyId, KeyringCompliance addressToEtch)
        KeyringCompliance(_poolManager, _keyring, _policyId)
    {
        Hooks.validateHookPermissions(addressToEtch, getHookPermissions());
    }

    // make this a no-op in testing
    function validateHookAddress(BaseHook _this) internal pure override {}
}

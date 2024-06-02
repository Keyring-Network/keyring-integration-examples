// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IKeyringCache {
    function checkCredential(address trader, uint32 admissionPolicyId) external view returns (bool passed);
}

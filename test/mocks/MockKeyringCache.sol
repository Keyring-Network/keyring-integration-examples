// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockKeyringCache {
    mapping(uint32 => mapping(address => bool)) private credentials;
    bool private degraded;

    function checkCredential(address trader, uint32 admissionPolicyId) external view returns (bool passed) {
        if (degraded) {
            return true;
        }
        return credentials[admissionPolicyId][trader];
    }

    function setCredential(address trader, uint32 admissionPolicyId, bool passed) external {
        credentials[admissionPolicyId][trader] = passed;
    }

    function getCredential(address trader, uint32 admissionPolicyId) external view returns (bool passed) {
        return credentials[admissionPolicyId][trader];
    }

    function setDegraded(bool _degraded) external {
        degraded = _degraded;
    }

    function getDegraded() external view returns (bool) {
        return degraded;
    }
}

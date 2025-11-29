// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Verifier.sol";

contract ZKPStorage {
    Groth16Verifier public verifier;

    constructor(address _verifier) {
        verifier = Groth16Verifier(_verifier);
    }

    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
        bool verified;
    }

    mapping(address => Proof) private proofs;

    event ProofStored(address indexed user, bool verified);

    function verifyAndStoreProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint inputValue
    ) public returns (bool) {
        uint[1] memory input = [inputValue];

        bool isValid = verifier.verifyProof(a, b, c, input);

        proofs[msg.sender] = Proof(a, b, c, input, isValid);

        emit ProofStored(msg.sender, isValid);
        return isValid;
    }

    function getMyProof() public view returns (
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input,
        bool verified
    ) {
        Proof memory p = proofs[msg.sender];
        return (p.a, p.b, p.c, p.input, p.verified);
    }
}
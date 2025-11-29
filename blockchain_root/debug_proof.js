const fs = require("fs");

// proof.jsonの読み込み
const proof = JSON.parse(fs.readFileSync("./proof/proof.json"));
const pub = JSON.parse(fs.readFileSync("./proof/public.json"));

console.log("Original proof data:");
console.log("pi_a:", proof.pi_a);
console.log("pi_b:", proof.pi_b);
console.log("pi_c:", proof.pi_c);
console.log("public:", pub);

// 現在の変換ロジック
const a = [
  BigInt(proof.pi_a[0]),
  BigInt(proof.pi_a[1])
];

const b = [
  [BigInt(proof.pi_b[0][1]), BigInt(proof.pi_b[0][0])],
  [BigInt(proof.pi_b[1][1]), BigInt(proof.pi_b[1][0])]
];

const c = [
  BigInt(proof.pi_c[0]),
  BigInt(proof.pi_c[1])
];

const inputValue = BigInt(pub[0]);

console.log("\nTransformed for Solidity:");
console.log("a:", a);
console.log("b:", b);
console.log("c:", c);
console.log("input:", inputValue);
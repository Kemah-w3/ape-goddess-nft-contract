const keccak256 = require("keccak256")
const { MerkleTree } = require("merkletreejs")
const { whitelistAddress } = require("./whitelistAddress.js")

//creation of merkle tree from an array of addresses
const whitelistAddressLeaves = whitelistAddress.map(x => keccak256(x))
const merkleTree = new MerkleTree(whitelistAddressLeaves, keccak256, {
    sortPairs: true
})

const rootHash = merkleTree.getHexRoot()
console.log("root is: ", rootHash)

//generating merkle proof 
const leaf = keccak256("0x81dbE0486ce6274984dF3b575911757E5522dc7E")
const proof = merkleTree.getHexProof(leaf)
console.log("proof is: ", proof)
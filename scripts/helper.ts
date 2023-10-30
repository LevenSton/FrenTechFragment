import { ethers, Contract } from 'ethers'

let deployer = ethers.Wallet.createRandom();
let gover = ethers.Wallet.createRandom();

console.log(deployer.privateKey)
console.log(gover.privateKey)
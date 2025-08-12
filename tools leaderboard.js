 // tools/leaderboard.js
require('dotenv').config();
const { ethers } = require('ethers');

const RPC = process.env.RPC_URL || 'http://127.0.0.1:8545';
const TOKENSTORE = process.env.TOKENSTORE_ADDRESS;

const provider = new ethers.providers.JsonRpcProvider(RPC);

// minimal ABI to watch Purchased events
const tokenStoreAbi = [ 'event Purchased(address indexed buyer, uint256 usdtAmount, uint256 gtAmount)' ];
const store = new ethers.Contract(TOKENSTORE, tokenStoreAbi, provider);

const wins = {};
const totalGT = {};

store.on('Purchased', (buyer, usdtAmount, gtAmount, event) => {
  console.log('Purchased', buyer, usdtAmount.toString(), gtAmount.toString());
});

console.log('Listening to events...');

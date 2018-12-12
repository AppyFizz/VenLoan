// const assert = require('assert');
// const ganache = require('ganache-cli');
// const Web3 = require('web3');
// const web3 = new Web3(ganache.provider());
// const json = require('./../build/contracts/Core.json');

// const interface = json['abi'];
// const bytecode = json['bytecode'];


// let accounts;
// let core;
// let borrower;
// let lender;

// beforeEach(async () => {
//     accounts = await web3.eth.getAccounts();
//     borrower = accounts[0];
//     lender = accounts[0];
//     core = await new web3.eth.Contract(interface)
//         .deploy({ data: bytecode })
//         .send({ from: borrower, gas: '1000000' });
//         core = await new web3.eth.Contract(interface)
//         .deploy({ data: bytecode })
//         .send({ from: lender, gas: '1000000' });
//   });



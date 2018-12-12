// // id = borrower.makeProposal(lender, due, amt, interest, freqPayments, collat, expiry)
// // lender.acceptProposal(id)
// // borrower.initiateLoan(id)

const App = artifacts.require("App");
const assert = require('assert');

var borrower = web3.eth.accounts[0];
var lender = web3.eth.accounts[1];

contract("App", accounts => {
    [borrower, lender] = accounts;
    it("creates proposal", async() => {
        const app = await App.new();
        await App.deployed().then((instance) => {
            instanceObj = instance;
            var start = 60 + Math.floor(Date.now() / 1000);
            return instance.makeProposal.call(
                lender,
                start,
                100,
                10,
                3,
                50,
                start + 3600,
                {from: borrower}
            );
        }).then((response) => {
            console.log(response.toNumber());
            assert(response.toNumber(), 0, "Creating Proposal Failed"); 
        });
      });

  it("creates and accepts proposal", async() => {
    [borrower, lender] = accounts;
    const app = await App.new();
    await App.deployed().then((instance) => {
        instanceObj = instance;
        var start = 60 + Math.floor(Date.now() / 1000);
        return instance.makeProposal(
            lender,
            start,
            100,
            10,
            3,
            50,
            start + 3600,
            {from: borrower}
        );
    }).then((response) => {
        return instanceObj.acceptProposal.call(
            0,
            {from: lender}
        );
    }).then((response) => {
        assert(response, true, "Accepting Proposal Failed");
    });
  });

});
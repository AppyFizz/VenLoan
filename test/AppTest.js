// // id = borrower.makeProposal(lender, due, amt, interest, freqPayments, collat, expiry)
// // lender.acceptProposal(id)
// // borrower.initiateLoan(id)

const App = artifacts.require("App");

contract("App", accounts => {
  const [borrower, lender] = accounts;

  it("creates proposal", async() => {
    const app = await App.new();
    const id = await app.makeProposal.value(10 finney)(
        lender,
        60 + Math.floor(Date.now() / 1000),
        100,
        10,
        3,
        50,
        3600,
    );
    console.log(id);
  });

  var result = await app.makeProposal( typeId , function(){} ,{ value:web3utils.toWei('0.00001','ether') })

// //   it("sets an owner", async () => {
// //     const app = await App.new();
// //     assert.equal(await app.owner.call(), borrower);
// //   });
// });
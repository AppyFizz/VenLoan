pragma solidity >=0.4.4 <0.6.0;

// TODO: Figure out how to use https://github.com/pipermerriam/ethereum-datetime ?
// TODO: Auto transactions prob wont work?

import "./Core.sol";

contract App {

    bytes32 POOL_ADDRESS = 0x42; // TODO

    /* 
     * The current status of the loan
     */
    enum Status {
        INIT, // Initialized
        PND,  // Pending
        ACC,  // Accepted
        REJ   // Rejected
    }

    /* 
     * The terms related to the loan
     */
    struct Terms {
        // due date
        uint32 start;
        uint32 due;
        uint32 numPay;
        uint32 amt;
        uint32 interest;
    }

    /* 
     * The collateral associated with the loan
     */
    struct Collateral {
        bytes32 location;
        uint32 valuation;
        address owner;
    }

    /* 
     * Representation of a loan proposal
     */
    struct Proposal {
        address borrower;
        address lender;
        Status status;
        Terms terms;
        Collateral collat;
    }

    Proposal prop;
    Core core;

    function makeProposal(
        address lender,
        uint32 start,
        uint32 due,
        uint32 amt,
        uint32 interest,
        uint32 numPay,

    ) external returns(uint) {
        
    }


    

    

    /*
     * Constructor: called when contract is deployed.
     */
    // function Loan() {
    //     ;
    // }



}
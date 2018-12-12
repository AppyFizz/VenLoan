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
        PND,  // Pending
        ACC,  // Accepted
        REJ,  // Rejected
        EXP,  // Expired
    }

    /* 
     * The terms related to the loan
     */
    struct Terms {
        uint32 due;          //due_date of the loan
        uint32 amt;          //amount of the loan
        uint32 freqPayments; //frequency of loan payments
        uint32 interest;     //annualized interest rate of the loan
    }

    /* 
     * Representation of a loan proposal
     */
    struct Proposal {
        address borrower; //address of the borrower
        address lender;   //address of the lender
        Status status;    //status of the proposal
        Terms terms;      //terms of the proposal
        uint32 collat;    //amount of staked collateral
        uint32 expiry;    // expiration date for the proposal, lender can no longer accept after this
    }

    Proposal[] private proposalList;
    
    mapping (address=>uint32[]) private lendProposals;
    mapping (address=>uint32[]) private borrowProposals;

    function makeProposal(
        address lender,
        uint32 due,
        uint32 amt,
        uint32 interest,
        uint32 freqPayments,
        uint32 collat,
        uint32 expiry
    ) external returns(uint32) {
        Terms newTerms = Terms(due, amt, freqPayments, interest);
        Proposal newProp = Proposal(msg.sender, lender, Status.PND, newTerms, collat, expiry);
        proposalList.push(Proposal);
        uint32 id = proposalList.length - 1;
        lendProposals[msg.sender].push(id);
        borrowProposals[lender].push(id);
        return id;
    }

    function acceptProposal(uint32 proposal_id) external returns(bool) {
        require(proposal_id < proposalList.length);
        Proposal prop = proposalList[proposal_id];
        if (prop.lender == msg.sender) {
            prop.status = Status.ACC;
            return true;
        }
        else {
            return false;
        }
    }
    
    function viewBorrowProposals() external returns(uint32[]) {
        return borrowProposals[msg.sender];
    }

    function viewLendProposals() external returns(uint32[]) {
        return lendProposals[msg.sender];
    }

    function initiateLoan(uint32 proposal_id) external payable returns(uint32) {
        require(proposal_id < proposalList.length);
        Proposal prop = proposalList[proposal_id];
        require(msg.value > prop.collat);
        if (prop.borrower == msg.sender && prop.status == Status.ACC) {
            uint32 loan_id = initLoan(prop.borrower, prop.lender, prop.terms.amt, prop.terms.interest, now, prop.due, prop.terms.freqPayments);
        }
        
    }

    function makePayment(

    ) external returns() {

    }

    function viewBalance(

    ) external returns() {

    }

    function viewLoanDetails(

    ) external returns() {

    }

    function viewPaymentHistory(

    ) external returns() {

    }


    /*
     * Constructor: called when contract is deployed.
     */
    // function Loan() {
    //     ;
    // }



}
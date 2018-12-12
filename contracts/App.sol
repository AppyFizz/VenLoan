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
        uint32 due;                     //due_date of the loan
        uint256 amt;                     //amount of the loan
        Core.RepayPeriod freqPayments;  //frequency of loan payments
        uint256 interest;                //annualized interest rate of the loan
    }

    /* 
     * Representation of a loan proposal
     */
    struct Proposal {
        address payable borrower; //address of the borrower
        address payable lender;   //address of the lender
        Status status;    //status of the proposal
        Terms terms;      //terms of the proposal
        uint256 collat;    //amount of staked collateral
        uint32 expiry;    // expiration date for the proposal, lender can no longer accept after this
    }

    Core core;
    Proposal[] private proposalList;
    Core[] private coreList;
    
    mapping (address=>uint32[]) private lendProposals;
    mapping (address=>uint32[]) private borrowProposals;
    mapping (address=>uint32[]) private loanList;
    mapping (address=>uint32[]) private activeBorrowers;

    function makeProposal(
        address payable lender,
        uint32 due,
        uint256 amt,
        uint256 interest,
        Core.RepayPeriod freqPayments,
        uint256 collat,
        uint32 expiry
    ) external returns(uint32) {
        Terms newTerms = Terms(due, amt, freqPayments, interest);
        Proposal newProp = Proposal(msg.sender, lender, Status.PND, newTerms, collat, expiry);
        proposalList.push(Proposal);
        int id = proposalList.length - 1;
        lendProposals[msg.sender].push(id);
        borrowProposals[lender].push(id);
        return id;
    }

    function acceptProposal(uint32 proposal_id) external returns(bool) {
        require(proposal_id < proposalList.length);
        Proposal prop = proposalList[proposal_id];
        if (prop.lender == msg.sender && prop.status == Status.PND) {
            if (prop.expiry < now) {
                prop.status = Status.EXP;
                return false;
            }
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

    function initiateLoan(uint32 proposal_id) external payable returns(int) {
        require(proposal_id < proposalList.length && activeBorrowers[msg.sender] != true);
        Proposal prop = proposalList[proposal_id];
        require(msg.value > prop.collat);
        if (prop.borrower == msg.sender && prop.status == Status.ACC) {
            core = new Core();
            core.initLoan(prop.borrower, prop.lender, prop.terms.amt, prop.terms.interest, now, prop.due, prop.terms.freqPayments);
            coreList.push(newLoad);
            int id = coreList.length - 1;
            loanList[prop.borrower].push(id);
            loanList[prop.lender].push(id);
            activeBorrowers[msg.sender] = true;
            return id;
        }
        return -1;
    }

    function makePayment() external payable returns(bool) {
        require(activeBorrowers[msg.sender] == true);
        int loan_id = loanList[msg.sender];
        core = coreList[loan_id];
        bool completion = address(core).makeLoanPayment.value(msg.value);
        if (completion == true) {
            activeBorrowers[msg.sender] = false;
        }
        return completion;
    }

    function viewBalance(int loan_id) external returns(uint32) {
        require(loan_id < coreList.length);
        core = coreList[loan_id];
        uint32 balance = core.getBalance();
        return balance;
    }

    function viewLoanDetails(int loan_id) external returns(
        uint256, uint256, 
        uint32, uint32, 
        Core.RepayPeriod, uint256){
        require(loan_id < coreList.length);
        core = coreList[loan_id];
        return core.getLoanInfo();
    }

    function viewPaymentHistory(int loan_id) external returns(Core.PaymentInfo[]) {
        require(loan_id < coreList.length);
        core = coreList[loan_id];
        return core.PayHistory();
    }

pragma solidity >=0.4.2 <0.6.0;

// TODO: Figure out how to use https://github.com/pipermerriam/ethereum-datetime ?
// TODO: Auto transactions prob wont work?

import "./Core.sol";

contract App {


    /* 
     * The current status of the loan
     */
    enum Status {
        PND,  // Pending
        ACC,  // Accepted
        REJ,  // Rejected
        EXP  // Expired
    }

    // id = borrower.makeProposal(lender, due, amt, interest, freqPayments, collat, expiry)
    // lender.acceptProposal(id)
    // borrower.initiateLoan(id)
    // 

    /* 
     * The terms related to the loan
     */
    struct Terms {
        uint256 due;                     //due_date of the loan
        uint256 amt;                     //amount of the loan
        Core.RepayPeriod freqPayments;  //frequency of loan payments
        uint256 interest;                //annualized interest rate of the loan
    }

    /* 
     * Representation of a loan proposal
     */
    struct Proposal {
        address borrower; //address of the borrower
        address lender;   //address of the lender
        Status status;    //status of the proposal
        Terms terms;      //terms of the proposal
        uint256 collat;    //amount of staked collateral
        uint256 expiry;    // expiration date for the proposal, lender can no longer accept after this
    }

    Core core;
    Proposal[] private proposalList;
    Core[] private coreList;
    
    mapping (address=>uint256[]) private lendProposals;
    mapping (address=>uint256[]) private borrowProposals;
    mapping (address=>uint256[]) private loanList;
    mapping (address=>bool) private activeBorrowers;

    function makeProposal(
        address lender,
        uint256 due,
        uint256 amt,
        uint256 interest,
        Core.RepayPeriod freqPayments,
        uint256 collat,
        uint256 expiry
    ) external returns(uint256) {
        Terms memory newTerms = Terms(due, amt, freqPayments, interest);
        Proposal memory newProp = Proposal(msg.sender, lender, Status.PND, newTerms, collat, expiry);
        proposalList.push(newProp);
        uint256 id = proposalList.length - 1;
        lendProposals[msg.sender].push(id);
        borrowProposals[lender].push(id);
        return id;
    }

    function acceptProposal(uint256 proposal_id) external view returns(bool) {
        require(proposal_id < proposalList.length);
        Proposal memory prop = proposalList[proposal_id];
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

    function rejectProposal(uint256 proposal_id) external view returns(bool) {
        require(proposal_id < proposalList.length);
        Proposal memory prop = proposalList[proposal_id];
        if ((prop.borrower == msg.sender || prop.borrower == msg.sender) && prop.status != Status.ACC) {
            prop.status = Status.REJ;
            return true;
        }
        return false;
    }
    
    function viewBorrowProposals() external view returns(uint256[] memory) {
        return borrowProposals[msg.sender];
    }

    function viewLendProposals() external view returns(uint256[] memory) {
        return lendProposals[msg.sender];
    }

    function initiateLoan(uint256 proposal_id) external payable returns(uint256) {
        require(proposal_id < proposalList.length && activeBorrowers[msg.sender] != true);
        Proposal memory prop = proposalList[proposal_id];
        require(msg.value > prop.collat);
        if (prop.borrower == msg.sender && prop.status == Status.ACC) {
            core = new Core();
            core.initLoan.value(msg.value)(prop.borrower, prop.lender, prop.terms.amt, prop.terms.interest, now, prop.terms.due, prop.terms.freqPayments, prop.collat);
            coreList.push(core);
            uint256 id = coreList.length - 1;
            loanList[prop.borrower].push(id);
            loanList[prop.lender].push(id);
            activeBorrowers[msg.sender] = true;
            return id;
        }
        return 0;
    }

    function sendPrincipal(uint256 core_id) external payable {
        core = coreList[core_id];
        core.deductPrincipal.value(msg.value)();
    }

    function makePayment(uint256 core_id) external payable returns(bool) {
        require(activeBorrowers[msg.sender] == true);
        core = coreList[core_id];
        bool completion = core.makeLoanPayment.value(msg.value)();
        if (completion == true) {
            activeBorrowers[msg.sender] = false;
        }
        return completion;
    }

    function viewBalance(uint256 loan_id) external returns(uint256) {
        require(loan_id < coreList.length);
        core = coreList[loan_id];
        uint256 balance = core.getBalance();
        return balance;
    }

    function viewLoanDetails(uint256 loan_id) external returns(
        uint256, uint256, 
        uint256, uint256, 
        Core.RepayPeriod, uint256){
        require(loan_id < coreList.length);
        core = coreList[loan_id];
        return core.getLoanInfo();
    }

    // function viewPaymentHistory(uint256 loan_id) external returns(Core.PaymentInfo[] memory) {
    //     require(loan_id < coreList.length);
    //     core = coreList[loan_id];
    //     return core.PayHistory();
    // }
}
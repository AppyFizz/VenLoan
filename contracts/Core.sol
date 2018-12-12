pragma solidity >=0.4.4 <0.6.0;

// TODO: Figure out how to use https://github.com/pipermerriam/ethereum-datetime ?
// TODO: Auto transactions prob wont work?


contract Core {

//     modifier loaneesOnly {
//       if(msg.sender != loan.actorAccounts.mortgageHolder) {
//          throw;
//       }
//       _;
//    }

    /**
     * 
     */
    enum RepayPeriod {
        WEEKLY,
        BI_WEEKLY,
        MONTHLY,
        QUARTERLY,
        BI_ANNUALLY
    }
    /**
     * The terms related to the loan
     */
    struct Terms {
        uint32 start;
        uint32 due;
        uint32 numPay;
        uint32 amt;
        uint32 interest;
    }
    /**
     * The collateral associated with the loan
     */
    struct Collateral {
        bytes32 location;
        uint32 valuation;
        address owner;
    }
    // Principal, interest
    // user makes payments every 'period'
    // frequency sepcifies the number of 'period's per year
    // if this payment is < yearlyInterest / numPeriods, subtract rest from collateral
    // yearlyInterest is calculated based on remaining principal

    /**
     * 
     */
    function initLoan(
        address borrower,
        address lender,
        uint32 amt,
        uint32 interest,
        uint32 start,
        uint32 due,
        RepayPeriod freq
    ) external {

    }


    // give all past payments and maybe their dates?
    function getRepayHistory() external returns (

    ) {

    }
    
    function getBalance() external returns (uint32) {

    }

    function getLoanInfo() external returns (
        uint32, // interest rate
        uint32, // start date
        uint32, // due date
        uint32  // num payments
    ) {
        
    }

    function makeLoanPayment(uint32 amt) external {
        
    }

    // called by auto-scheduler
    // if at least interest not paid for this period, deduct it from collateral,
    // otherwise (if collat over) neg balance for user? and deduct from pool
    function ensureLoanPayment() private {
        
    }

}
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
        uint256 principal;
        uint256 annual_int_rate;
        uint32 start_date;
        uint32 due_date;
        RepayPeriod period;
        uint256 min_collateral;
    }

     /**
     * 
     */
    struct PaymentInfo {
        uint32 timestamp;
        uint256 interest_due;
        uint256 from_borrower;
        uint256 from_collateral;
    }

    PaymentInfo[] public PayHistory = new PaymentInfo[](0);

    // Principal, interest
    // user makes payments every 'period'
    // frequency sepcifies the number of 'period's per year
    // if this payment is < yearlyInterest / numPeriods, subtract rest from collateral
    // yearlyInterest is calculated based on remaining principal

    struct State {
        uint256 principal_rem;
        uint256 interest;
        uint32 pay_period;
        uint32 last_payed;
        uint32 next_due;
    }

    struct Loan {
        address payable borrower;
        address payable lender;
        uint256 collateral;
        Terms terms;
        State state;
    }

    bool init_called = false;
    bool mutex = true;

    Loan loan;
    bool collateral_deducted = false;

    /**
     * 
     */
    function initLoan(
        address payable borrower,
        address payable lender,
        uint256 amount,
        uint256 interest,
        uint32 start,
        uint32 due,
        RepayPeriod period,
        uint256 min_collat
    ) external {
        require(!init_called, "initLoan() called more than once");

        loan = Loan({
            borrower: borrower,
            lender: lender
        });
   
        loan.terms = Terms({
            principal: amount,
            annual_int_rate: interest,
            start_date: start,
            due_date: due,
            period: period,
            min_collateral: min_collat
        });
   
        loan.state = State({
            principal_rem: amount,
            interest: (interest * amount) / (100 * per2Freq(period)),
            pay_period: period,
            next_due: getTime(start, toDays(period))
        }); 
   
        init_called = true;
    }

    function deductCollateral() external payable {
        require (init_called, "deductCollateral() called before initLoan()");
        require (msg.value >= loan.terms.min_collateral, "not enough collateral passed to deductCollateral()");
        
        require (mutex, "deductCollateral() couldn't obtain lock");
        mutex = false;
        
        loan.collateral = msg.value;
        
        mutex = true;
    }

    function getBalance() external returns (uint256) {
        return loan.state.principal_rem;
    }

    function getNextDue() external returns (uint32, uint256) {
        return (loan.state.next_due, loan.state.interest);
    }

    function getLoanInfo() external returns (
        uint256, uint256,
        uint32, uint32,
        RepayPeriod, uint256
    ) {
        return (
            loan.terms.principal,
            loan.terms.annual_int_rate,
            loan.terms.start_date,
            loan.terms.due_date,
            loan.terms.period,
            loan.collateral
        );
    }

    function makeLoanPayment() external payable returns (bool) {
        require (init_called, "makeLoanPayment() called before initLoan()");
        
        require (mutex, "makeLoanPayment() couldn't obtain lock");
        mutex = false;

        PaymentInfo memory pay_info = PaymentInfo({
            timestamp: now,
            interest_due: loan.state.interest,
            from_borrower: msg.value,
            from_collateral: 0
        });

        uint256 extra = msg.value - loan.state.interest;
        if (extra < 0) {
            pay_info.from_collateral = -extra;
            loan.collateral -= extra;
        } else if (extra >= loan.state.principal_rem) {
            pay_info.from_borrower = loan.state.interest + loan.state.principal_rem;
            loan.borrower.transfer(extra - loan.state.principal_rem);
            loan.state.principal_rem = 0;
        } else {
            loan.state.principal_rem -= extra;
            loan.state.interest = (loan.terms.annual_int_rate * loan.state.principal_rem) / (100 * per2Freq(loan.terms.period));
        }

        loan.lender.transfer(pay_info.from_borrower + pay_info.from_collateral);

        loan.state.last_payed = pay_info.timestamp;
        loan.state.next_due = getTime(loan.state.next_due, toDays(loan.terms.period));
        
        PayHistory.push(pay_info);

        bool loan_paid = loan.state.principal_rem <= 0;  
        mutex = true;

        return loan_paid;
    }

    // called by auto-scheduler
    // if at least interest not paid for this period, deduct it from collateral,
    // otherwise (if collat over) neg balance for user? and deduct from pool
    function ensureLoanPayment() private {
        
    }

    function getDays(uint32 start, uint32 end) private returns (uint32) {
        return (end - start) / 86400;
    }

    function getTime(uint32 start, uint32 num_days) private returns (uint32) {
        return start + num_days * 86400;
    }

    function per2Freq(RepayPeriod period) private returns (uint32) {
        if (period == RepayPeriod.WEEKLY) {
            return 52;
        } else if (period == RepayPeriod.BI_WEEKLY) {
            return 26;
        } else if (period == RepayPeriod.MONTHLY) {
            return 12;
        } else if (period == RepayPeriod.QUARTERLY) {
            return 4;
        } else if (period == RepayPeriod.BI_ANNUALLY) {
            return 2;
        } else {
            // Not possible
        }
    }

    function toDays(RepayPeriod period) private returns(uint32) {
        if (period == RepayPeriod.WEEKLY) {
            return 7;
        } else if (period == RepayPeriod.BI_WEEKLY) {
            return 14;
        } else if (period == RepayPeriod.MONTHLY) {
            return 30;
        } else if (period == RepayPeriod.QUARTERLY) {
            return 90;
        } else if (period == RepayPeriod.BI_ANNUALLY) {
            return 180;
        } else {
            // Not possible
        }
    }

}
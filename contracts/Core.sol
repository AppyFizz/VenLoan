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
        uint32 principal;
        uint32 annual_int_rate;
        uint32 start_date;
        uint32 due_date;
        RepayPeriod frequency;
        uint32 min_collateral;
    }

     /**
     * 
     */
    struct PaymentInfo {
        uint32 timestamp;
        uint32 interest_due;
        uint32 from_borrower;
        uint32 from_collateral;
    }

    // Principal, interest
    // user makes payments every 'period'
    // frequency sepcifies the number of 'period's per year
    // if this payment is < yearlyInterest / numPeriods, subtract rest from collateral
    // yearlyInterest is calculated based on remaining principal

    struct State {
        uint32 principal_rem;
        uint32 interest;
        uint32 pay_period;
        uint32 last_payed;
        uint32 next_due;
        PaymentInfo[] paid;
    }

    struct Loan {
        address borrower;
        address lender;
        uint32 collateral;
        Terms terms;
    }

    bool init_called = false;
    bool mutex = true;

    Loan loan;
    bool collateral_deducted = false;

    /**
     * 
     */
    function initLoan(
        address borrower,
        address lender,
        uint32 amount,
        uint32 interest,
        uint32 start,
        uint32 due,
        RepayPeriod freq,
        uint32 min_collat
    ) external {
        require(!init_called);
   
        terms = new Terms({
            principal: amount,
            annual_int_rate: interest,
            start_date: start,
            due_date: due,
            frequency: freq,
            min_collateral: min_collat
        });
   
        state = new State({
            principal_rem: amount,
            interest: (interest * amount) / (100 * period),
            pay_period: period,
            next_due: getTime(start, toDays(period)),
            paid: new PaymentInfo[](0)
        }); 
   
        loan = new Loan({
            borrower: borrower,
            lender: lender,
            terms: terms,
            state: state
        });
   
        init_called = true;
    }

    function deductCollateral() external payable {
        require (init_called);
        require (msg.value >= loan.terms.min_collateral);
        require (mutex);
        mutex = false;
        loan.collateral = msg.value;
        mutex = true;
    }

    // borrower calls --> deductCollateral
    // lender calls --> deductLoanAmount

    // give all past payments and maybe their dates?
    function getRepayHistory() external returns (PaymentInfo[]) {
        return loan.state.paid;
    }

    function getBalance() external returns (uint32) {
        return loan.state.principal_rem;
    }

    function getNextDue() external returns (uint32, uint32) {
        return (loan.state.next_due, loan.state.interest);
    }

    function getLoanInfo() external returns (
        uint32, uint32,
        uint32, uint32,
        uint32, uint32
    ) {
        return (
            loan.terms.principal,
            loan.terms.annual_int_rate,
            loan.terms.start,
            loan.terms.due,
            loan.terms.frequency,
            loan.terms.min_collateral
        );
    }

    function makeLoanPayment() external payable {
        require (init_called);
        require (mutex);
        mutex = false;

        loan.lender.send(loan.state.interest);

        pay_info = new PaymentInfo({
            timestamp: now,
            interest_due: loan.state.interest,
            from_borrower: msg.value,
        });

        extra = msg.value - loan.state.interest;
        if (extra < 0) {
            pay_info.from_collateral = -extra;
        } else {
            loan.state.principal_rem -= extra;
            loan.state.interest = (loan.terms.annual_int_rate * loan.state.principal_rem) / (100 * period),
        }

        loan.state.last_payed = pay_info.timestamp;
        loan.state.next_due = getTime(loan.state.next_due, toDays(period));
        
        loan.state.paid.push(pay_info);

        mutex = true;
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

    function toDays(RepayPeriod period) private returns(uint32) {
        if (period == WEEKLY) {
            return 7;
        } else if (period == BI_WEEKLY) {
            return 14;
        } else if (period == MONTHLY) {
            return 30;
        } else if (period == QUARTERLY) {
            return 90;
        } else if (period == BI_ANNUALLY) {
            return 180;
        } else {
            // Not possible
        }
    }

}
pragma solidity >=0.4.2 <0.6.0;

// TODO: Figure out how to use https://github.com/pipermerriam/ethereum-datetime ?
// TODO: Auto transactions prob wont work?


contract Core {

    /**
     * Payments made every:
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
        uint256 start_date;
        uint256 due_date;
        RepayPeriod period;
        uint256 min_collateral;
    }

     /**
     * Info about past payments
     */
    struct PaymentInfo {
        uint256 timestamp;
        uint256 interest_due;
        uint256 from_borrower;
        uint256 from_collateral;
    }

    /**
     * Publicly accessible, to read pay history
     */
    PaymentInfo[] public PayHistory;

    struct State {
        uint256 principal_rem;
        uint256 interest;
        RepayPeriod pay_period;
        uint256 last_payed;
        uint256 next_due;
    }

    struct Loan {
        address borrower;
        address lender;
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
        address borrower,
        address lender,
        uint256 amount,
        uint256 interest,
        uint256 start,
        uint256 due,
        RepayPeriod period,
        uint256 min_collat
    ) external payable {
        require(!init_called, "initLoan() called more than once");
        require (msg.value >= min_collat, "not enough collateral passed to initLoan()");

        State memory state = State({
            principal_rem: amount,
            last_payed: 0,
            interest: (interest * amount) / (100 * per2Freq(period)),
            pay_period: period,
            next_due: getTime(start, toDays(period))
        });

        Terms memory terms = Terms({
            principal: amount,
            annual_int_rate: interest,
            start_date: start,
            due_date: due,
            period: period,
            min_collateral: min_collat
        });

        loan = Loan({
            borrower: borrower,
            lender: lender,
            collateral: 0,
            terms: terms,
            state: state
        });

        loan.collateral = msg.value;
   
        init_called = true;
    }

    function deductPrincipal() external payable {
        require (init_called, "deductPrincipal() called before initLoan()");
        require (msg.value == loan.terms.principal, "wrong principal amount passed to deductPrincipal()");
        loan.borrower.transfer(msg.value);
    }

    function getBalance() external view returns (uint256) {
        return loan.state.principal_rem;
    }

    function getNextDue() external view returns (uint256, uint256) {
        return (loan.state.next_due, loan.state.interest);
    }

    function getLoanInfo() external view returns (
        uint256, uint256,
        uint256, uint256,
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
    // function ensureLoanPayment() private {
        
    // }

    function getDays(uint256 start, uint256 end) private pure returns (uint256) {
        return (end - start) / 86400;
    }

    function getTime(uint256 start, uint256 num_days) private pure returns (uint256) {
        return start + num_days * 86400;
    }

    function per2Freq(RepayPeriod period) private pure returns (uint256) {
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

    function toDays(RepayPeriod period) private pure returns(uint256) {
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
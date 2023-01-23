

module {

    public type State = {
        #OnHold;
        #Approved;
        #Denied : ?Text;
    };

    public type Proposal = {
        text: Text;
        principalId: Principal;
        amount: Nat;
        state: State;
        votes: Nat;
    };

    public type ProposalSuccess = {
        text: Text;
        principalId: Principal;
        amount: Nat;
        state: State;
        votes: Nat;
    };

    public type ErrorProposal = {
        #InsufficentBalance;
    };

};
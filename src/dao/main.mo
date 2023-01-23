// Official project for Motoko Bootcamp 2023 ~ 
import { print } "mo:base/Debug";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import T "./Types";
import U "./utils/Account";
import Result "mo:base/Result";
import Prelude "mo:base/Prelude";
import Iter "mo:base/Iter";
import Bool "mo:base/Bool";
import Option "mo:base/Option";

//MBT canister : db3eq-6iaaa-aaaah-abz6a-cai

actor DAO_TOM{

    stable var proposals: Trie.Trie<Nat, T.Proposal> = Trie.empty();

    stable var balance: Nat = 0;

    stable var proposalId: Nat = 0;

    public type Subaccount = [Nat8];

    public type Account__1 = { owner : Principal; subaccount : ?Subaccount };

    //utils -> Key Nat -> Id for Trie...
     private func keyNat(x : Nat) : Trie.Key<Nat> {
      return { key = x; hash = Hash.hash(x) }
    };

    // public shared ({caller}) func verify_payment(): async Nat{

    // };

    public shared ({caller}) func verify_balance(): async Text{
    let mb_tokens = actor("db3eq-6iaaa-aaaah-abz6a-cai") : actor {
      icrc1_balance_of : shared query (Account__1) -> async Nat ;
      icrc1_name : shared query () -> async Text;
    };

    var subAccountWithPrincipal = U.principalToSubaccount(caller);
    var subAccount = U.accountIdentifier(caller, subAccountWithPrincipal);

    var accountId = {
        owner = caller;
        subaccount = Text.decodeUtf8(subAccount);
    };

    print(debug_show(accountId));

    var result = await mb_tokens.icrc1_name();

    print(debug_show(result));

    return result;

    };

    // This function submit a proposal for be draw in the front
    public shared ({caller}) func submit_proposal(new_text: Text): async Result.Result<T.ProposalSuccess, T.ErrorProposal> { //
        
        proposalId += 1;

       var newProposal = {
            text: Text = new_text;
            principalId= caller;
            amount: Nat = 1;
            state = #OnHold; 
            votes = 0;
       };


        let (newProposalResult, exists) = Trie.put(
            proposals,
            keyNat(proposalId),
            Nat.equal,
            newProposal
        );

        switch(exists){
            case(null){
                proposals := newProposalResult;
                return #ok(newProposal);
            };
            case(_){
                return #err(#InsufficentBalance);
            };
        };

    };


    // This function get a specific proposal 
    public func get_proposal(id: Nat) : async Result.Result<T.ProposalSuccess, Text>{
        var proposalRes = Trie.find(
            proposals,
            keyNat(id),
            Nat.equal
        );

        switch(proposalRes) {
            case(null) { 
                return #err("Sorry, not exist proposal");
             };
            case( ?proposalRes ) { 
                return #ok(proposalRes);
            };
        };

    };

    // This function get all proposals in the Trie?? HashMap ??
    public query func get_all_proposals() : async Result.Result<[(Nat, T.Proposal)], Text>{
    var allProposals = Iter.toArray(Trie.iter(proposals));

    if(allProposals == []){
        return #err("Sorry, don't exists proposals, maybe you can try create one...")
    }else{
        return #ok(allProposals);
    };

    };

    // This functions you can vote just only you get a Token MB in your wallet ... !!!! Principal type in param
    public shared ({caller}) func vote(id: Nat): async Result.Result<T.ProposalSuccess, Text>{
        var proposalRes = Trie.find(
            proposals,
            keyNat(id),
            Nat.equal
        );

        switch(proposalRes) {
            case(null) { 
                return #err("No exists Proposal");
             };
            case(?proposalRes) { 
                var addVotes: T.Proposal = {
                    amount = proposalRes.amount;
                    principalId = proposalRes.principalId;
                    state = proposalRes.state;
                    text = proposalRes.text;
                    votes = proposalRes.votes + 1;
                };

                proposals := Trie.replace(
                    proposals,
                    keyNat(id),
                    Nat.equal,
                    ?addVotes
                ).0;

            return #ok(addVotes);

            };
        };
    };

    public shared ({caller}) func updated_proposal(id: Nat, new_text: Text): async Result.Result<T.ProposalSuccess, Text>{
        var proposalRes = Trie.find(
            proposals,
            keyNat(id),
            Nat.equal
        );

        switch(proposalRes) {
            case(null) { 
                return #err("No exists Proposal");
             };
            case(?proposalRes) { 
                var updatedValues: T.ProposalSuccess = {
                    amount = proposalRes.amount;
                    state = proposalRes.state;
                    principalId = caller;
                    text = new_text;
                    votes = proposalRes.votes;
                };

                proposals := Trie.replace(
                    proposals,
                    keyNat(id),
                    Nat.equal,
                    ?updatedValues
                ).0;
                
            return #ok(updatedValues);
            };
        };
    };

    private func remove_proposal(id: Nat): async Result.Result<T.ProposalSuccess, Text>{
        var proposalRes = Trie.find(
            proposals,
            keyNat(id),
            Nat.equal
        );

        switch(proposalRes) {
            case(null) { 
                return #err("No exists Proposal");
             };
            case(?proposalRes) { 
                proposals := Trie.replace(
                    proposals,
                    keyNat(id),
                    Nat.equal,
                    null
                ).0;
            return #ok(proposalRes);
            };
        };
    };

};
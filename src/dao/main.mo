// Official project for Motoko Bootcamp 2023 ~ 
import { print } "mo:base/Debug";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import T "./Types";
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

    //utils -> Key Nat -> Id for Trie...
     private func keyNat(x : Nat) : Trie.Key<Nat> {
      return { key = x; hash = Hash.hash(x) }
    };

    public shared ({caller}) func verify_mbTokens(): async Nat{

    let mb_tokens = actor("db3eq-6iaaa-aaaah-abz6a-cai") : actor {
      icrc1_balance_of : query (Principal) -> async (Nat) 
    };

    var result = await mb_tokens.icrc1_balance_of(caller);

    return result;

    };

    // This function submit a proposal for be draw in the front
    public func create_proposal(new_text: Text, new_amount: Nat): async Result.Result<T.ProposalSuccess, T.ErrorProposal> { //
        
        proposalId += 1;

       var newProposal = {
            text: Text = new_text;
            amount: Nat = 1;
            state = #OnHold; 
            votes = 0;
       };

        if(new_amount > 1){
            print("You can't submit more of 1MB");
            newProposal := {
            text: Text = new_text;
            amount: Nat = 1;
            state = #OnHold; 
            votes = 0;
        }
        }else{
            newProposal := {
            text: Text = new_text;
            amount: Nat = new_amount;
            state = #OnHold; 
            votes = 0;
        }
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
    public func get_all_proposal() : async Result.Result<[(Nat, T.Proposal)], Text>{
    var allProposals = Iter.toArray(Trie.iter(proposals));

    if(allProposals == []){
        return #err("Sorry, don't exists proposals, maybe you can try create one...")
    }else{
        return #ok(allProposals);
    };

    };

    // This functions you can vote just only you get a Token MB in your wallet ... !!!! Principal type in param
    public func vote(id: Nat): async Result.Result<T.ProposalSuccess, Text>{
        var proposalRes = Trie.find(
            proposals,
            keyNat(id),
            Nat.equal
        );

        // var addVotes = {
        //     text: Text = proposalResult;
        //     amount: Nat = 1;
        //     state = #OnHold; 
        //     votes = 0;
        // };


        switch(proposalRes) {
            case(null) { 
                return #err("No exists Proposal");
             };
            case(?proposalRes) { 
                var addVotes: T.Proposal = {
                    amount = proposalRes.amount;
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

};
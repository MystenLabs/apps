module quorum_upgrade_policy::proposal;

use quorum_upgrade_policy::quorum_upgrade_v2::QuorumUpgrade;
use sui::vec_set::{Self, VecSet};

public struct Proposal<T> has key, store {
    id: UID,
    creator: address,
    quorum_upgrade: ID,
    votes: VecSet<address>,
    data: T,
}

// hot potato object use to cast vote
public struct Vote {
    voter: address,
    proposal_id: ID,
}

public fun new<T: store>(quorum_upgrade: &QuorumUpgrade, data: T, ctx: &mut TxContext) {
    // only voters can create proposal
    assert!(quorum_upgrade.voters().contains(&ctx.sender()));

    let proposal = Proposal {
        id: object::new(ctx),
        creator: ctx.sender(),
        quorum_upgrade: object::id(quorum_upgrade),
        votes: vec_set::empty(),
        data,
    };
    transfer::share_object(proposal);
}

public fun vote<T>(proposal: &mut Proposal<T>, vote: Vote) {
    let Vote { voter, proposal_id } = vote;
    assert!(!proposal.votes.contains(&voter));
    assert!(proposal.id.to_inner() == proposal_id);
    proposal.votes.insert(voter);
}

public fun create_vote<T>(
    quorum_upgrade: &QuorumUpgrade,
    proposal: &Proposal<T>,
    ctx: &mut TxContext,
): Vote {
    assert!(quorum_upgrade.voters().contains(&ctx.sender()));
    Vote {
        voter: ctx.sender(),
        proposal_id: proposal.id.to_inner(),
    }
}

public fun quorum_reached<T>(proposal: &Proposal<T>, quorum_upgrade: &QuorumUpgrade): bool {
    let current_votes = proposal.votes.size();
    let required_votes = quorum_upgrade.required_votes();
    current_votes >= required_votes
}

public fun delete_proposal_by_creator<T: drop>(proposal: Proposal<T>, ctx: &mut TxContext) {
    assert!(proposal.creator == ctx.sender());
    proposal.delete();
}

public(package) fun execute<T: drop>(proposal: Proposal<T>, quorum_upgrade: &QuorumUpgrade) {
    assert!(proposal.quorum_reached(quorum_upgrade));
    assert!(proposal.quorum_upgrade == object::id(quorum_upgrade));
    proposal.delete();
}

public(package) fun delete<T: drop>(proposal: Proposal<T>) {
    let Proposal<T> {
        id,
        creator: _creator,
        quorum_upgrade: _quorum_upgrade,
        votes: _votes,
        data: _data,
    } = proposal;
    id.delete();
}

// read functions

public fun data<T: copy>(proposal: &Proposal<T>): T {
    proposal.data
}

public fun quorum_upgrade<T: copy>(proposal: &Proposal<T>): ID {
    proposal.quorum_upgrade
}

public fun votes<T: copy>(proposal: &Proposal<T>): &VecSet<address> {
    &proposal.votes
}

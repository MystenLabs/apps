// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_policy::quorum_upgrade_policy_v2;

use sui::event;
use sui::package::UpgradeCap;
use sui::vec_set::{Self, VecSet};

public struct QuorumUpgrade has key, store {
    id: UID,
    upgrade_cap: UpgradeCap,
    required_votes: u64,
    voters: VecSet<address>,
}

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
    proposal: ID,
}

public fun new(
    upgrade_cap: UpgradeCap,
    required_votes: u64,
    voters: VecSet<address>,
    ctx: &mut TxContext,
) {
    let id = object::new(ctx);
    let quorum_upgrade = QuorumUpgrade {
        id,
        upgrade_cap,
        required_votes,
        voters,
    };
    transfer::share_object(quorum_upgrade);
}

public fun create_proposal<T: store>(quorum_upgrade: &QuorumUpgrade, data: T, ctx: &mut TxContext) {
    // only voters can create proposal
    assert!(quorum_upgrade.voters.contains(&ctx.sender()));
    let id = object::new(ctx);
    let proposal = Proposal {
        id,
        creator: ctx.sender(),
        quorum_upgrade: quorum_upgrade.id.to_inner(),
        votes: vec_set::empty(),
        data,
    };
    transfer::share_object(proposal);
}

public fun create_vote<T>(
    quorum_upgrade: &QuorumUpgrade,
    proposal: &Proposal<T>,
    ctx: &mut TxContext,
): Vote {
    assert!(quorum_upgrade.voters.contains(&ctx.sender()));
    Vote {
        voter: ctx.sender(),
        proposal: proposal.id.to_inner(),
    }
}

public fun cast_vote<T>(proposal: &mut Proposal<T>, vote: Vote) {
    let Vote { voter, proposal: _proposal } = vote;
    assert!(!proposal.votes.contains(&voter));
    assert!(proposal.id.to_inner() == _proposal);
    proposal.votes.insert(voter);
}

public fun delete_proposal<T: drop>(proposal: Proposal<T>, ctx: &mut TxContext) {
    // only creator can delete proposal
    assert!(proposal.creator == ctx.sender());

    let Proposal<T> {
        id,
        creator: _creator,
        quorum_upgrade: _quorum_upgrade,
        votes: _votes,
        data: _data,
    } = proposal;
    id.delete();
}

public fun quorum_reached<T>(proposal: &Proposal<T>, quorum_upgrade: &QuorumUpgrade): bool {
    let current_votes = proposal.votes.size();
    let required_votes = quorum_upgrade.required_votes;
    current_votes >= required_votes
}

public(package) fun add_voter(
    quorum_upgrade: &mut QuorumUpgrade,
    voter: address,
    new_required_votes: u64,
) {
    quorum_upgrade.voters.insert(voter);
    quorum_upgrade.required_votes = new_required_votes;
}

public(package) fun remove_voter(
    quorum_upgrade: &mut QuorumUpgrade,
    voter: address,
    new_required_votes: u64,
) {
    quorum_upgrade.voters.remove(&voter);
    quorum_upgrade.required_votes = new_required_votes;
}

public(package) fun replace_voter(
    quorum_upgrade: &mut QuorumUpgrade,
    old_voter: address,
    new_voter: address,
) {
    quorum_upgrade.voters.remove(&old_voter);
    quorum_upgrade.voters.insert(new_voter);
}

public(package) fun relinquish_quorum(quorum_upgrade: QuorumUpgrade, new_owner: address) {
    let QuorumUpgrade {
        id,
        upgrade_cap,
        required_votes: _required_votes,
        voters: _voters,
    } = quorum_upgrade;

    id.delete();

    transfer::public_transfer(upgrade_cap, new_owner);
}

public fun data<T: copy>(proposal: &Proposal<T>): T {
    proposal.data
}

public fun quorum_upgrade<T: copy>(proposal: &Proposal<T>): ID {
    proposal.quorum_upgrade
}

public fun votes<T: copy>(proposal: &Proposal<T>): &VecSet<address> {
    &proposal.votes
}

public fun voters(quorum_upgrade: &QuorumUpgrade): &VecSet<address> {
    &quorum_upgrade.voters
}

public fun required_votes(quorum_upgrade: &QuorumUpgrade): u64 {
    quorum_upgrade.required_votes
}

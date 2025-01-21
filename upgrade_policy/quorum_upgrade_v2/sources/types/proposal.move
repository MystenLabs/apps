// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::proposal;

use quorum_upgrade_v2::events;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use sui::vec_set::{Self, VecSet};

// ~~~~~~~ Structs ~~~~~~~

public struct Proposal<T> has key, store {
    id: UID,
    creator: address,
    quorum_upgrade: ID,
    votes: VecSet<address>,
    data: T,
}

// ~~~~~~~ Errors ~~~~~~~
#[error]
const EUnauthorizedCaller: vector<u8> = b"Caller must be a quorum voter";
#[error]
const ECallerNotCreator: vector<u8> = b"Caller must be the proposal creator";
#[error]
const EQuorumNotReached: vector<u8> = b"Quorum not reached";
#[error]
const EProposalQuorumMismatch: vector<u8> = b"Proposal quorum mismatch";

// ~~~~~~~ Public Functions ~~~~~~~

public fun new<T: store>(quorum_upgrade: &QuorumUpgrade, data: T, ctx: &mut TxContext) {
    // only voters can create proposal
    assert!(quorum_upgrade.voters().contains(&ctx.sender()), EUnauthorizedCaller);
    let votes = vec_set::from_keys(vector[ctx.sender()]);

    let proposal = Proposal {
        id: object::new(ctx),
        creator: ctx.sender(),
        quorum_upgrade: object::id(quorum_upgrade),
        votes,
        data,
    };
    transfer::share_object(proposal);
}

public fun vote<T>(proposal: &mut Proposal<T>, ctx: &mut TxContext) {
    assert!(!proposal.votes.contains(&ctx.sender()), EUnauthorizedCaller);
    proposal.votes.insert(ctx.sender());

    events::emitVoteCastEvent(proposal.id.to_inner(), proposal.votes.size());
}

public fun quorum_reached<T>(proposal: &Proposal<T>, quorum_upgrade: &QuorumUpgrade): bool {
    let current_votes = proposal.votes.size();
    let required_votes = quorum_upgrade.required_votes();
    current_votes >= required_votes
}

public fun delete_proposal_by_creator<T: drop>(proposal: Proposal<T>, ctx: &mut TxContext) {
    assert!(proposal.creator == ctx.sender(), ECallerNotCreator);
    events::emitProposalDeletedEvent(proposal.id.to_inner());
    proposal.delete();
}

// ~~~~~~~ Package Functions ~~~~~~~

public(package) fun execute<T>(proposal: Proposal<T>, quorum_upgrade: &QuorumUpgrade): T {
    assert!(proposal.quorum_reached(quorum_upgrade), EQuorumNotReached);
    assert!(proposal.quorum_upgrade == object::id(quorum_upgrade), EProposalQuorumMismatch);
    events::emitProposalExecutedEvent(proposal.id.to_inner());
    proposal.delete()
}

public(package) fun delete<T>(proposal: Proposal<T>): T {
    let Proposal<T> {
        id,
        data,
        ..,
    } = proposal;
    id.delete();
    data
}

// ~~~~~~~ Getters                                                                                                                                                                                                                                                                                                                                                                          ~~~~~~~

public fun data<T>(proposal: &Proposal<T>): &T {
    &proposal.data
}

public fun quorum_upgrade<T>(proposal: &Proposal<T>): ID {
    proposal.quorum_upgrade
}

public fun votes<T>(proposal: &Proposal<T>): &VecSet<address> {
    &proposal.votes
}

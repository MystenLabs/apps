// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::proposal;

use quorum_upgrade_v2::events;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use std::string::String;
use sui::vec_map::VecMap;

// ~~~~~~~ Structs ~~~~~~~

public struct Proposal<T> has key, store {
    id: UID,
    creator: address,
    quorum_upgrade: ID,
    votes: vector<address>,
    metadata: VecMap<String, String>,
    data: T,
}

// ~~~~~~~ Errors ~~~~~~~
#[error]
const EUnauthorizedCaller: vector<u8> = b"Caller must be a quorum voter";
#[error]
const EVoteAlreadyCounted: vector<u8> = b"Vote already counted";
#[error]
const ECallerNotCreator: vector<u8> = b"Caller must be the proposal creator";
#[error]
const EQuorumNotReached: vector<u8> = b"Quorum not reached";
#[error]
const EProposalQuorumMismatch: vector<u8> = b"Proposal quorum mismatch";
#[error]
const ENoVoteFound: vector<u8> = b"Vote doesn't exist";

// ~~~~~~~ Public Functions ~~~~~~~

public fun new<T: store>(
    quorum_upgrade: &QuorumUpgrade,
    data: T,
    metadata: VecMap<String, String>,
    ctx: &mut TxContext,
) {
    // only voters can create proposal
    assert!(quorum_upgrade.voters().contains(&ctx.sender()), EUnauthorizedCaller);
    let votes = vector[ctx.sender()];

    let proposal = Proposal {
        id: object::new(ctx),
        creator: ctx.sender(),
        quorum_upgrade: object::id(quorum_upgrade),
        votes,
        metadata,
        data,
    };
    transfer::share_object(proposal);
}

public fun vote<T>(
    proposal: &mut Proposal<T>,
    quorum_upgrade: &QuorumUpgrade,
    ctx: &mut TxContext,
) {
    validate_proposal!<T>(quorum_upgrade, proposal, ctx.sender());
    assert!(!proposal.votes.contains(&ctx.sender()), EVoteAlreadyCounted);

    proposal.votes.push_back(ctx.sender());
    events::emit_vote_cast_event(proposal.id.to_inner(), ctx.sender());
    if (proposal.quorum_reached(quorum_upgrade)) {
        events::emit_quorum_reached_event(proposal.id.to_inner());
    }
}

public fun remove_vote<T>(
    proposal: &mut Proposal<T>,
    quorum_upgrade: &QuorumUpgrade,
    ctx: &mut TxContext,
) {
    validate_proposal!<T>(quorum_upgrade, proposal, ctx.sender());

    let (vote_exists, index) = proposal.votes.index_of(&ctx.sender());
    assert!(vote_exists, ENoVoteFound);

    proposal.votes.remove(index);
    events::emit_vote_removed_event(proposal.id.to_inner(), ctx.sender());
}

public fun quorum_reached<T>(proposal: &Proposal<T>, quorum_upgrade: &QuorumUpgrade): bool {
    let valid_votes = proposal.votes.fold!(0, |acc, voter| {
        if (quorum_upgrade.voters().contains(&voter)) {
            acc + 1
        } else {
            acc
        }
    });
    valid_votes >= quorum_upgrade.required_votes()
}

public fun delete_by_creator<T: drop>(proposal: Proposal<T>, ctx: &mut TxContext) {
    assert!(proposal.creator == ctx.sender(), ECallerNotCreator);
    events::emit_proposal_deleted_event(proposal.id.to_inner());
    proposal.delete();
}

// ~~~~~~~ Package Functions ~~~~~~~

public(package) fun execute<T>(proposal: Proposal<T>, quorum_upgrade: &QuorumUpgrade): T {
    assert!(proposal.quorum_reached(quorum_upgrade), EQuorumNotReached);
    assert!(proposal.quorum_upgrade == object::id(quorum_upgrade), EProposalQuorumMismatch);
    events::emit_proposal_executed_event(proposal.id.to_inner());
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

macro fun validate_proposal<$T>(
    $quorum_upgrade: &QuorumUpgrade,
    $proposal: &Proposal<$T>,
    $sender: address,
) {
    let quorum_upgrade = $quorum_upgrade;
    let proposal = $proposal;
    let sender = $sender;
    assert!(quorum_upgrade.voters().contains(&sender), EUnauthorizedCaller);
    assert!(proposal.quorum_upgrade == object::id(quorum_upgrade), EProposalQuorumMismatch);
}

// ~~~~~~~ Getters ~~~~~~~                                                                                                                                                                                                                                                                                                                                                              ~~~~~~~

public fun quorum_upgrade<T>(proposal: &Proposal<T>): ID {
    proposal.quorum_upgrade
}

public fun votes<T>(proposal: &Proposal<T>): &vector<address> {
    &proposal.votes
}

#[test_only]
public fun data<T>(proposal: &Proposal<T>): &T {
    &proposal.data
}

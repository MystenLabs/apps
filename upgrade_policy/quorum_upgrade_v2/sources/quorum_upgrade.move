// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::quorum_upgrade;

use sui::event;
use sui::package::{Self, UpgradeCap, UpgradeTicket, UpgradeReceipt};
use sui::table_vec::{Self, TableVec};
use sui::vec_set::VecSet;

public struct QuorumUpgrade has key, store {
    id: UID,
    upgrade_cap: UpgradeCap,
    required_votes: u64,
    voters: VecSet<address>,
    proposals: TableVec<ID>,
}

// ~~~~~~~ Events ~~~~~~~

public struct VoterAddedEvent has copy, drop {
    quorum_upgrade_id: ID,
    voter: address,
    new_required_votes: u64,
}

public struct VoterRemovedEvent has copy, drop {
    proposal_id: ID,
    voter: address,
    new_required_votes: u64,
}

public struct VoterReplacedEvent has copy, drop {
    proposal_id: ID,
}

public struct RequiredVotesChangedEvent has copy, drop {
    proposal_id: ID,
    new_required_votes: u64,
}

public struct QuorumRelinquishedEvent has copy, drop {
    proposal_id: ID,
    new_required_votes: u64,
}

// ~~~~~~~ Public Functions ~~~~~~~

public fun new(
    upgrade_cap: UpgradeCap,
    required_votes: u64,
    voters: VecSet<address>,
    ctx: &mut TxContext,
) {
    assert!(required_votes > 0);
    assert!(voters.size() >= required_votes);

    let id = object::new(ctx);
    let quorum_upgrade = QuorumUpgrade {
        id,
        upgrade_cap,
        required_votes,
        voters,
        proposals: table_vec::empty(ctx),
    };
    transfer::share_object(quorum_upgrade);
}

public fun replace_voter_by_owner(
    quorum_upgrade: &mut QuorumUpgrade,
    new_voter: address,
    ctx: &mut TxContext,
) {
    replace_voter(quorum_upgrade, ctx.sender(), new_voter)
}

public fun commit_upgrade(quorum_upgrade: &mut QuorumUpgrade, receipt: UpgradeReceipt) {
    package::commit_upgrade(&mut quorum_upgrade.upgrade_cap, receipt)
}

// ~~~~~~~ Package Functions ~~~~~~~

public(package) fun add_voter(
    quorum_upgrade: &mut QuorumUpgrade,
    voter: address,
    new_required_votes: u64,
) {
    quorum_upgrade.voters.insert(voter);
    quorum_upgrade.required_votes = new_required_votes;

    event::emit(VoterAddedEvent {
        quorum_upgrade_id: quorum_upgrade.id.to_inner(),
        voter,
        new_required_votes,
    });
}

public(package) fun remove_voter(
    quorum_upgrade: &mut QuorumUpgrade,
    voter: address,
    new_required_votes: u64,
) {
    quorum_upgrade.voters.remove(&voter);
    quorum_upgrade.required_votes = new_required_votes;

    event::emit(VoterRemovedEvent {
        proposal_id: quorum_upgrade.id.to_inner(),
        voter,
        new_required_votes,
    });
}

public(package) fun replace_voter(
    quorum_upgrade: &mut QuorumUpgrade,
    old_voter: address,
    new_voter: address,
) {
    // double check assertions for replace_voter_by_owner
    assert!(quorum_upgrade.voters.contains(&old_voter));
    assert!(!quorum_upgrade.voters.contains(&new_voter));

    quorum_upgrade.voters.remove(&old_voter);
    quorum_upgrade.voters.insert(new_voter);

    event::emit(VoterReplacedEvent {
        proposal_id: quorum_upgrade.id.to_inner(),
    });
}

public(package) fun update_required_votes(
    quorum_upgrade: &mut QuorumUpgrade,
    new_required_votes: u64,
) {
    quorum_upgrade.required_votes = new_required_votes;

    event::emit(RequiredVotesChangedEvent {
        proposal_id: quorum_upgrade.id.to_inner(),
        new_required_votes,
    });
}

public(package) fun relinquish_quorum(quorum_upgrade: QuorumUpgrade, new_owner: address) {
    let QuorumUpgrade {
        id,
        upgrade_cap,
        proposals: proposals,
        ..,
    } = quorum_upgrade;

    event::emit(QuorumRelinquishedEvent {
        proposal_id: id.to_inner(),
        new_required_votes: 0,
    });

    id.delete();

    proposals.drop();

    transfer::public_transfer(upgrade_cap, new_owner);
}

public(package) fun authorize_upgrade(
    quorum_upgrade: &mut QuorumUpgrade,
    digest: vector<u8>,
): UpgradeTicket {
    let policy = package::upgrade_policy(&quorum_upgrade.upgrade_cap);
    package::authorize_upgrade(
        &mut quorum_upgrade.upgrade_cap,
        policy,
        digest,
    )
}

// ~~~~~~~ Getters ~~~~~~~

public fun voters(quorum_upgrade: &QuorumUpgrade): &VecSet<address> {
    &quorum_upgrade.voters
}

public fun required_votes(quorum_upgrade: &QuorumUpgrade): u64 {
    quorum_upgrade.required_votes
}

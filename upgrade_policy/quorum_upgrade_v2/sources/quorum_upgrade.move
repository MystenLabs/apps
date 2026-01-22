// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::quorum_upgrade;

use quorum_upgrade_v2::events;
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

// ~~~~~~~ ERRORS ~~~~~~~

#[error]
const EInvalidZeroRequiredVotes: vector<u8> = b"Required votes must be greater than 0";
#[error]
const EInvalidVoters: vector<u8> = b"Voter set must contain at least the required number of votes";
#[error]
const EInvalidOldVoter: vector<u8> = b"Old voter does not exist in the quorum";
#[error]
const EInvalidNewVoter: vector<u8> = b"New voter already exists in the quorum";

// ~~~~~~~ Public Functions ~~~~~~~

public fun new(
    upgrade_cap: UpgradeCap,
    required_votes: u64,
    voters: VecSet<address>,
    ctx: &mut TxContext,
) {
    assert!(required_votes > 0, EInvalidZeroRequiredVotes);
    assert!(voters.length() >= required_votes, EInvalidVoters);

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

public fun replace_self(
    quorum_upgrade: &mut QuorumUpgrade,
    new_voter: address,
    ctx: &mut TxContext,
) {
    quorum_upgrade.replace_voter(ctx.sender(), new_voter)
}

public fun commit_upgrade(quorum_upgrade: &mut QuorumUpgrade, receipt: UpgradeReceipt) {
    package::commit_upgrade(&mut quorum_upgrade.upgrade_cap, receipt)
}

// ~~~~~~~ Package Functions ~~~~~~~

public(package) fun add_voter(quorum_upgrade: &mut QuorumUpgrade, voter: address) {
    quorum_upgrade.voters.insert(voter);
    events::emit_voter_added_event(quorum_upgrade.id.to_inner(), voter);
}

public(package) fun remove_voter(quorum_upgrade: &mut QuorumUpgrade, voter: address) {
    quorum_upgrade.voters.remove(&voter);
    events::emit_voter_removed_event(quorum_upgrade.id.to_inner(), voter);
}

public(package) fun replace_voter(
    quorum_upgrade: &mut QuorumUpgrade,
    old_voter: address,
    new_voter: address,
) {
    // double check assertions for replace_self
    assert!(quorum_upgrade.voters.contains(&old_voter), EInvalidOldVoter);
    assert!(!quorum_upgrade.voters.contains(&new_voter), EInvalidNewVoter);
    quorum_upgrade.voters.remove(&old_voter);
    quorum_upgrade.voters.insert(new_voter);
    events::emit_voter_replaced_event(quorum_upgrade.id.to_inner(), old_voter, new_voter);
}

public(package) fun update_threshold(quorum_upgrade: &mut QuorumUpgrade, new_required_votes: u64) {
    quorum_upgrade.required_votes = new_required_votes;
    events::emit_threshold_updated_event(quorum_upgrade.id.to_inner(), new_required_votes);
}

public(package) fun relinquish_quorum(quorum_upgrade: QuorumUpgrade, new_owner: address) {
    let QuorumUpgrade {
        id,
        upgrade_cap,
        proposals: proposals,
        ..,
    } = quorum_upgrade;
    events::emit_quorum_relinquished_event(id.to_inner());

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

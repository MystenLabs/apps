// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_policy::quorum_upgrade_v2;

use sui::event;
use sui::package::{Self, UpgradeCap, UpgradeTicket, UpgradeReceipt};
use sui::vec_set::{Self, VecSet};

public struct QuorumUpgrade has key, store {
    id: UID,
    upgrade_cap: UpgradeCap,
    required_votes: u64,
    voters: VecSet<address>,
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

public(package) fun update_required_votes(
    quorum_upgrade: &mut QuorumUpgrade,
    new_required_votes: u64,
) {
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

public fun voters(quorum_upgrade: &QuorumUpgrade): &VecSet<address> {
    &quorum_upgrade.voters
}

public fun required_votes(quorum_upgrade: &QuorumUpgrade): u64 {
    quorum_upgrade.required_votes
}

public fun commit_upgrade(quorum_upgrade: &mut QuorumUpgrade, receipt: UpgradeReceipt) {
    package::commit_upgrade(&mut quorum_upgrade.upgrade_cap, receipt)
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

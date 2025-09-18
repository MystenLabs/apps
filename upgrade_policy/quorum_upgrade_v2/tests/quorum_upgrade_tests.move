// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::quorum_upgrade_tests;

use quorum_upgrade_v2::quorum_upgrade::{Self, QuorumUpgrade};
use sui::object::id_from_address as id;
use sui::package::{Self, UpgradeCap};
use sui::test_scenario;
use sui::vec_set;

#[test]
public(package) fun new_quorum_upgrade() {
    let (voter1, voter2, voter3) = (@0x1, @0x2, @0x3);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    let cap = package::test_publish(id(@0x42), scenario.ctx());
    let voters = vec_set::from_keys(vector[voter1, voter2, voter3]);
    quorum_upgrade::new(cap, 2, voters, scenario.ctx());

    scenario.next_tx(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    assert!(quorum_upgrade.required_votes() == 2);
    assert!(quorum_upgrade.voters().length() == 3);

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test]
fun replace_quorum_voter_by_owner() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let mut quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    quorum_upgrade.replace_self(new_voter, scenario.ctx());

    assert!(quorum_upgrade.voters().length() == 3);
    assert!(quorum_upgrade.voters().contains(&new_voter));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test]
fun add_voter() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let mut quorum_upgrade;

    let scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    quorum_upgrade.add_voter(new_voter);

    assert!(quorum_upgrade.voters().length() == 4);
    assert!(quorum_upgrade.voters().contains(&new_voter));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test]
fun remove_voter() {
    new_quorum_upgrade();

    let (voter1, voter2) = (@0x1, @0x2);
    let mut quorum_upgrade;

    let scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    quorum_upgrade.remove_voter(voter2);

    assert!(quorum_upgrade.voters().length() == 2);
    assert!(!quorum_upgrade.voters().contains(&voter2));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test]
fun replace_voter() {
    new_quorum_upgrade();

    let (voter1, voter2, new_voter) = (@0x1, @0x2, @0x4);
    let mut quorum_upgrade;

    let scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    quorum_upgrade.replace_voter(voter2, new_voter);

    assert!(quorum_upgrade.voters().length() == 3);
    assert!(!quorum_upgrade.voters().contains(&voter2));
    assert!(quorum_upgrade.voters().contains(&new_voter));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test]
fun update_threshold() {
    new_quorum_upgrade();

    let voter1 = @0x1;
    let mut quorum_upgrade;

    let scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    quorum_upgrade.update_threshold(1);

    assert!(quorum_upgrade.required_votes() == 1);

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test]
fun relinquish_quorum() {
    new_quorum_upgrade();

    let (voter1, new_owner) = (@0x1, @0x4);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    quorum_upgrade.relinquish_quorum(new_owner);

    scenario.next_tx(voter1);
    let upgrade_cap = scenario.take_from_address<UpgradeCap>(new_owner);
    test_scenario::return_to_address(new_owner, upgrade_cap);

    scenario.end();
}

#[
    test,
    expected_failure(
        abort_code = ::quorum_upgrade_v2::quorum_upgrade::EInvalidZeroRequiredVotes,
    ),
]
fun new_quorum_upgrade_zero_failure() {
    let (voter1, voter2, voter3) = (@0x1, @0x2, @0x3);

    let mut scenario = test_scenario::begin(voter1);
    let cap = package::test_publish(id(@0x42), scenario.ctx());
    let voters = vec_set::from_keys(vector[voter1, voter2, voter3]);
    quorum_upgrade::new(cap, 0, voters, scenario.ctx());
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::quorum_upgrade::EInvalidVoters)]
fun new_quorum_upgrade_required_votes_failure() {
    let (voter1, voter2) = (@0x1, @0x2);

    let mut scenario = test_scenario::begin(voter1);
    let cap = package::test_publish(id(@0x42), scenario.ctx());
    let voters = vec_set::from_keys(vector[voter1, voter2]);
    quorum_upgrade::new(cap, 3, voters, scenario.ctx());
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::quorum_upgrade::EInvalidOldVoter)]
fun replace_quorum_old_voter_failure() {
    new_quorum_upgrade();

    let (voter1, _voter2, _voter3, voter4, voter5) = (@0x1, @0x2, @0x3, @0x4, @0x5);
    let mut quorum_upgrade;

    let scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    quorum_upgrade.replace_voter(voter4, voter5);
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::quorum_upgrade::EInvalidNewVoter)]
fun replace_quorum_new_voter_failure() {
    new_quorum_upgrade();

    let (voter1, voter2) = (@0x1, @0x2);
    let mut quorum_upgrade;

    let scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    quorum_upgrade.replace_voter(voter1, voter2);
    abort 1337
}

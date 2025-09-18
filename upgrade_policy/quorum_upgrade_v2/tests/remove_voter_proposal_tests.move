// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::remove_voter_proposal_tests;

use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use quorum_upgrade_v2::remove_voter::{Self, RemoveVoter};
use sui::test_scenario;
use sui::vec_map;

#[test]
fun remove_voter_proposal() {
    new_quorum_upgrade();
    let (voter1, voter2, voter3) = (@0x1, @0x2, @0x3);
    let mut quorum_upgrade;
    let mut proposal;
    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    scenario.next_tx(voter1);
    let remove_voter_proposal = remove_voter::new(&quorum_upgrade, voter3, option::none());
    proposal::new(&quorum_upgrade, remove_voter_proposal, vec_map::empty(), scenario.ctx());
    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<RemoveVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));
    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));
    scenario.next_tx(voter1);
    remove_voter::execute(proposal, &mut quorum_upgrade);
    assert!(quorum_upgrade.voters().length() == 2);
    assert!(!quorum_upgrade.voters().contains(&voter3));
    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test]
fun remove_voter_and_update_required() {
    new_quorum_upgrade();
    let (voter1, voter2, voter3) = (@0x1, @0x2, @0x3);
    let mut quorum_upgrade;
    let mut proposal;
    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    scenario.next_tx(voter1);
    let remove_voter_proposal = remove_voter::new(&quorum_upgrade, voter3, option::some(1));
    proposal::new(&quorum_upgrade, remove_voter_proposal, vec_map::empty(), scenario.ctx());
    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<RemoveVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));
    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));
    scenario.next_tx(voter1);
    remove_voter::execute(proposal, &mut quorum_upgrade);
    assert!(quorum_upgrade.voters().length() == 2);
    assert!(!quorum_upgrade.voters().contains(&voter3));
    assert!(quorum_upgrade.required_votes() == 1);
    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::remove_voter::EInvalidVoter)]
fun invalid_voter() {
    new_quorum_upgrade();
    let (voter1, new_voter) = (@0x1, @0x4);
    let quorum_upgrade;
    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    scenario.next_tx(voter1);
    // Try remove voter not in quorum
    remove_voter::new(&quorum_upgrade, new_voter, option::some(1));
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::remove_voter::ERequiredVotesZero)]
fun invalid_zero_required_votes() {
    new_quorum_upgrade();
    let (voter1, voter3) = (@0x1, @0x3);
    let quorum_upgrade;
    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    scenario.next_tx(voter1);
    // Try and add a voter with less than 1 required votes
    remove_voter::new(&quorum_upgrade, voter3, option::some(0));
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::remove_voter::EInvalidRequiredVotes)]
fun invalid_required_votes() {
    new_quorum_upgrade();

    let (voter1, voter3) = (@0x1, @0x3);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    scenario.next_tx(voter1);

    // Try and add a voter with less than 1 required votes
    remove_voter::new(&quorum_upgrade, voter3, option::some(6));
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::remove_voter::EInvalidRequiredVotes)]
fun invalid_removed_voters() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3) = (@0x1, @0x2, @0x3);
    let mut quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    scenario.next_tx(voter1);

    quorum_upgrade.remove_voter(voter3);

    remove_voter::new(&quorum_upgrade, voter2, option::none());
    abort 1337
}

// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::add_voter_proposal_test;

use quorum_upgrade_v2::add_voter::{Self, AddVoter};
use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use sui::test_scenario;
use sui::vec_map;

#[test]
fun add_voter_proposal() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3, new_voter) = (@0x1, @0x2, @0x3, @0x4);
    let mut quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::none());
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());

    scenario.next_tx(voter3);
    add_voter::execute(proposal, &mut quorum_upgrade);

    assert!(quorum_upgrade.voters().length() == 4);
    assert!(quorum_upgrade.voters().contains(&new_voter));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}
#[test]
fun add_voter_update_required_votes() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3, new_voter) = (@0x1, @0x2, @0x3, @0x4);
    let mut quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));

    scenario.next_tx(voter3);
    add_voter::execute(proposal, &mut quorum_upgrade);
    assert!(quorum_upgrade.voters().length() == 4);
    assert!(quorum_upgrade.voters().contains(&new_voter));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::add_voter::EInvalidNewVoter)]
fun invalid_new_voter() {
    new_quorum_upgrade();

    let (voter1, voter3) = (@0x1, @0x3);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    // Try and add a voter already in quorum
    add_voter::new(&quorum_upgrade, voter3, option::some(3));
    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::add_voter::ERequiredVotesZero)]
fun invalid_zero_required_votes() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    // Try and add a voter with less than 1 required votes
    add_voter::new(&quorum_upgrade, new_voter, option::some(0));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::add_voter::EInvalidRequiredVotes)]
fun invalid_required_votes() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    // Try and add a voter with less than 1 required votes
    add_voter::new(&quorum_upgrade, new_voter, option::some(5));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

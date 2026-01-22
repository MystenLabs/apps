// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::update_threshold_proposal_tests;

use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use quorum_upgrade_v2::update_threshold::{Self, UpdateThreshold};
use sui::test_scenario;
use sui::vec_map;

#[test]
fun update_threshold_proposal() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3) = (@0x1, @0x2, @0x3);
    let mut quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let update_threshold_proposal = update_threshold::new(
        &quorum_upgrade,
        3,
    );
    proposal::new(
        &quorum_upgrade,
        update_threshold_proposal,
        vec_map::empty(),
        scenario.ctx(),
    );

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<UpdateThreshold>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));

    scenario.next_tx(voter3);
    update_threshold::execute(proposal, &mut quorum_upgrade);
    assert!(quorum_upgrade.voters().length() == 3);
    assert!(quorum_upgrade.required_votes() == 3);

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::update_threshold::ERequiredVotesZero)]
fun invalid_zero_required_votes() {
    new_quorum_upgrade();

    let (voter1) = (@0x1);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    // Try and add a voter with less than 1 required votes
    update_threshold::new(&quorum_upgrade, 0);
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::update_threshold::EInvalidRequiredVotes)]
fun invalid_required_votes() {
    new_quorum_upgrade();
    let (voter1) = (@0x1);
    let quorum_upgrade;
    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    scenario.next_tx(voter1);
    // Try and add a voter with less than 1 required votes
    update_threshold::new(&quorum_upgrade, 5);
    abort 1337
}

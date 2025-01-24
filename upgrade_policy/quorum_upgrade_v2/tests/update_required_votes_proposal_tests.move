// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::update_required_votes_proposal_tests;

use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use quorum_upgrade_v2::update_required_votes::{Self, UpdateRequiredVotes};
use sui::test_scenario;

#[test]
fun update_required_votes_proposal() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3) = (@0x1, @0x2, @0x3);
    let mut quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let update_required_votes_proposal = update_required_votes::new(
        &quorum_upgrade,
        3,
    );
    proposal::new(&quorum_upgrade, update_required_votes_proposal, option::none(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<UpdateRequiredVotes>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));

    scenario.next_tx(voter3);
    update_required_votes::execute(proposal, &mut quorum_upgrade);
    assert!(quorum_upgrade.voters().size() == 3);
    assert!(quorum_upgrade.required_votes() == 3);

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[
    test,
    expected_failure(
        abort_code = ::quorum_upgrade_v2::update_required_votes::ERequiredVotesZero,
    ),
]
fun invalid_zero_required_votes() {
    new_quorum_upgrade();

    let (voter1) = (@0x1);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    // Try and add a voter with less than 1 required votes
    update_required_votes::new(&quorum_upgrade, 0);
    abort 1337
}

#[
    test,
    expected_failure(
        abort_code = ::quorum_upgrade_v2::update_required_votes::EInvalidRequiredVotes,
    ),
]
fun invalid_required_votes() {
    new_quorum_upgrade();
    let (voter1) = (@0x1);
    let quorum_upgrade;
    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    scenario.next_tx(voter1);
    // Try and add a voter with less than 1 required votes
    update_required_votes::new(&quorum_upgrade, 5);
    abort 1337
}

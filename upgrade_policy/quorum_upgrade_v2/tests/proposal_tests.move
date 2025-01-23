// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::proposal_tests;

use quorum_upgrade_v2::add_voter::{Self, AddVoter};
use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use sui::test_scenario;

#[test]
#[expected_failure(abort_code = ::quorum_upgrade_v2::proposal::EUnauthorizedCaller)]
fun invalid_new_proposal() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(new_voter);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, option::none(), scenario.ctx());

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test]
fun vote() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3, new_voter) = (@0x1, @0x2, @0x3, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, option::none(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter2);
    proposal.vote(scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));

    scenario.next_tx(voter3);
    proposal.vote(scenario.ctx());
    assert!(proposal.votes().length() == 3);
    assert!(proposal.votes().contains(&voter3));

    transfer::public_share_object(quorum_upgrade);
    transfer::public_share_object(proposal);
    scenario.end();
}

#[test]
fun quorum_reached() {
    new_quorum_upgrade();

    let (voter1, voter2, new_voter) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, option::none(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    assert!(!proposal.quorum_reached(&quorum_upgrade));

    scenario.next_tx(voter2);
    proposal.vote(scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));

    assert!(proposal.quorum_reached(&quorum_upgrade));

    transfer::public_share_object(quorum_upgrade);
    transfer::public_share_object(proposal);
    scenario.end();
}

#[test]
fun delete_by_creator() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let quorum_upgrade;
    let proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, option::none(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter1);
    proposal.delete_by_creator(scenario.ctx());

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

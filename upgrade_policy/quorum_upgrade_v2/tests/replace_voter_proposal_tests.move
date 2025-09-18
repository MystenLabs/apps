// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::replace_voter_proposal_tests;

use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use quorum_upgrade_v2::replace_voter::{Self, ReplaceVoter};
use sui::test_scenario;
use sui::vec_map;

#[test]
fun replace_voter_proposal() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3, new_voter) = (@0x1, @0x2, @0x3, @0x4);
    let mut quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = replace_voter::new(&quorum_upgrade, new_voter, voter3);
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<ReplaceVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));

    scenario.next_tx(voter3);
    replace_voter::execute(proposal, &mut quorum_upgrade);
    assert!(quorum_upgrade.voters().length() == 3);
    assert!(!quorum_upgrade.voters().contains(&voter3));
    assert!(quorum_upgrade.voters().contains(&new_voter));

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::replace_voter::EInvalidNewVoter)]
fun invalid_new_voter() {
    new_quorum_upgrade();

    let (voter1, voter2) = (@0x1, @0x2);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    replace_voter::new(&quorum_upgrade, voter2, voter1);
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::replace_voter::EInvalidOldVoter)]
fun invalid_old_voter() {
    new_quorum_upgrade();

    let (voter1, new_voter1, new_voter2) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    replace_voter::new(&quorum_upgrade, new_voter1, new_voter2);
    abort 1337
}

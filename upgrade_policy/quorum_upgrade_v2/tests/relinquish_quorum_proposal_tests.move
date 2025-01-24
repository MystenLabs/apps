// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::relinquish_quorum_proposal_tests;

use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use quorum_upgrade_v2::relinquish_quorum::{Self, RelinquishQuorum};
use sui::package::UpgradeCap;
use sui::test_scenario;
use sui::vec_map;

#[test]
fun relinquish_quorum_proposal() {
    new_quorum_upgrade();

    let (voter1, voter2, new_owner) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);

    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let relinquish_quorum_proposal = relinquish_quorum::new(new_owner);
    proposal::new(&quorum_upgrade, relinquish_quorum_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter2);
    proposal = scenario.take_shared<Proposal<RelinquishQuorum>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));

    scenario.next_tx(voter1);
    relinquish_quorum::execute(proposal, quorum_upgrade);
    scenario.next_tx(voter1);
    let upgrade_cap = scenario.take_from_address<UpgradeCap>(new_owner);
    transfer::public_transfer(upgrade_cap, new_owner);
    scenario.end();
}

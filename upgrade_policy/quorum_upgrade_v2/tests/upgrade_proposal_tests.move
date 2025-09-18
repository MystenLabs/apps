// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::upgrade_proposal_tests;

use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use quorum_upgrade_v2::upgrade::{Self, Upgrade};
use sui::package;
use sui::test_scenario;
use sui::vec_map;

#[test]
fun upgrade_proposal() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3) = (@0x1, @0x2, @0x3);
    let mut quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();
    let digest: vector<u8> = x"0123456789";

    scenario.next_tx(voter1);
    let upgrade_proposal = upgrade::new(digest);
    proposal::new(&quorum_upgrade, upgrade_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<Upgrade>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 2);
    assert!(proposal.votes().contains(&voter2));

    scenario.next_tx(voter3);
    let upgradeTicket = upgrade::execute(proposal, &mut quorum_upgrade);

    let receipt = package::test_upgrade(upgradeTicket);

    quorum_upgrade.commit_upgrade(receipt);

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

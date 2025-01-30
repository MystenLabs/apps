// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_v2::proposal_tests;

use quorum_upgrade_v2::add_voter::{Self, AddVoter};
use quorum_upgrade_v2::events::QuorumReachedEvent;
use quorum_upgrade_v2::proposal::{Self, Proposal};
use quorum_upgrade_v2::quorum_upgrade::{Self, QuorumUpgrade};
use quorum_upgrade_v2::quorum_upgrade_tests::new_quorum_upgrade;
use sui::event;
use sui::object::id_from_address as id;
use sui::package;
use sui::test_scenario;
use sui::vec_map;
use sui::vec_set;

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
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

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
    proposal.vote(&quorum_upgrade, scenario.ctx());
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
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    assert!(!proposal.quorum_reached(&quorum_upgrade));

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
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
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    assert!(proposal.votes().length() == 1);
    assert!(proposal.votes().contains(&voter1));

    scenario.next_tx(voter1);
    proposal.delete_by_creator(scenario.ctx());

    transfer::public_share_object(quorum_upgrade);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::EUnauthorizedCaller)]
fun vote_by_non_voter() {
    new_quorum_upgrade();

    let (voter1, _voter2, new_voter) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();

    scenario.next_tx(new_voter);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::EVoteAlreadyCounted)]
fun vote_already_counted() {
    new_quorum_upgrade();

    let (voter1, _voter2, new_voter) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();

    scenario.next_tx(voter1);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    abort 1337
}

// create proposal, remove voter, try and vote with that voter
#[test]
fun invalid_votes_not_counted() {
    new_quorum_upgrade();

    let (voter1, _voter2, voter3, new_voter) = (@0x1, @0x2, @0x3, @0x4);
    let mut quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter3);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    proposal.vote(&quorum_upgrade, scenario.ctx());

    scenario.next_tx(voter3);
    assert!(proposal.quorum_reached(&quorum_upgrade) == true);
    quorum_upgrade.remove_voter(voter1);
    assert!(proposal.quorum_reached(&quorum_upgrade) == false);

    transfer::public_share_object(quorum_upgrade);
    transfer::public_share_object(proposal);
    scenario.end();
}

#[test]
fun remove_vote() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);

    let mut scenario = test_scenario::begin(voter1);
    let quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    let mut proposal = scenario.take_shared<Proposal<AddVoter>>();

    scenario.next_tx(voter1);
    proposal.remove_vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.votes().length() == 0);
    assert!(!proposal.votes().contains(&voter1));

    transfer::public_share_object(quorum_upgrade);
    transfer::public_share_object(proposal);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::EUnauthorizedCaller)]
fun invalid_remove_vote_by_non_voter() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(new_voter);
    proposal = scenario.take_shared<Proposal<AddVoter>>();

    scenario.next_tx(new_voter);
    proposal.remove_vote(&quorum_upgrade, scenario.ctx());
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::EProposalQuorumMismatch)]
fun mismatch_quorum_upgrade_remove_vote() {
    new_quorum_upgrade();

    let (voter1, voter2, new_voter) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();

    let cap = package::test_publish(id(@0x42), scenario.ctx());
    let voters = vec_set::from_keys(vector[voter1, voter2]);
    quorum_upgrade::new(cap, 2, voters, scenario.ctx());

    scenario.next_tx(voter1);
    let temp_quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    proposal.remove_vote(&temp_quorum_upgrade, scenario.ctx());
    abort 1337
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::ENoVoteFound)]
fun invalid_remove_vote_with_no_vote_found() {
    new_quorum_upgrade();

    let (voter1, voter2, new_voter) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();

    scenario.next_tx(voter2);
    proposal.remove_vote(&quorum_upgrade, scenario.ctx());
    abort 1337
}

// try and delete proposal by non-creator
#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::ECallerNotCreator)]
fun invalid_delete_by_non_creator() {
    new_quorum_upgrade();

    let (voter1, voter2, new_voter) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();

    scenario.next_tx(voter2);
    proposal.delete_by_creator(scenario.ctx());
    abort 1337
}

// execute proposal with insufficient votes
#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::EQuorumNotReached)]
fun invalid_execute_insufficient_votes() {
    new_quorum_upgrade();

    let (voter1, _voter2, new_voter) = (@0x1, @0x2, @0x4);
    let mut quorum_upgrade;
    let proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    add_voter::execute(proposal, &mut quorum_upgrade);

    abort 1337
}

// execute proposal using wrong quorum upgrade
#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::EProposalQuorumMismatch)]
fun mismatch_quorum_upgrade_execution() {
    new_quorum_upgrade();

    let (voter1, voter2, new_voter) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter2);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    proposal.vote(&quorum_upgrade, scenario.ctx());

    let cap = package::test_publish(id(@0x42), scenario.ctx());
    let voters = vec_set::from_keys(vector[voter1, voter2]);
    quorum_upgrade::new(cap, 2, voters, scenario.ctx());

    scenario.next_tx(voter1);
    let mut temp_quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter2);
    add_voter::execute(proposal, &mut temp_quorum_upgrade);
    abort 1337
}

// check proposal data value
#[test]
fun proposal_data_value() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let quorum_upgrade;
    let proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    let add_voter = proposal.data();
    assert!(add_voter.voter() == new_voter);
    assert!(add_voter.required_votes() == option::some(3));

    transfer::public_share_object(quorum_upgrade);
    transfer::public_share_object(proposal);
    scenario.end();
}

// check proposal quorum_upgrade value
#[test]
fun proposal_quorum_upgrade_value() {
    new_quorum_upgrade();

    let (voter1, new_voter) = (@0x1, @0x4);
    let quorum_upgrade;
    let proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    assert!(proposal.quorum_upgrade() == object::id(&quorum_upgrade));

    transfer::public_share_object(quorum_upgrade);
    transfer::public_share_object(proposal);
    scenario.end();
}

#[test, expected_failure(abort_code = ::quorum_upgrade_v2::proposal::EProposalQuorumMismatch)]
fun mismatch_quorum_upgrade_vote() {
    new_quorum_upgrade();

    let (voter1, voter2, voter3, new_voter) = (@0x1, @0x2, @0x3, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter2);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    proposal.vote(&quorum_upgrade, scenario.ctx());

    let cap = package::test_publish(id(@0x42), scenario.ctx());
    let voters = vec_set::from_keys(vector[voter1, voter2, voter3]);
    quorum_upgrade::new(cap, 2, voters, scenario.ctx());

    scenario.next_tx(voter1);
    let temp_quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter3);
    proposal.vote(&temp_quorum_upgrade, scenario.ctx());
    abort 1337
}

#[test]
fun proposal_reached_event_emitted_on_vote() {
    new_quorum_upgrade();

    let (voter1, voter2, new_voter) = (@0x1, @0x2, @0x4);
    let quorum_upgrade;
    let mut proposal;

    let mut scenario = test_scenario::begin(voter1);
    quorum_upgrade = scenario.take_shared<QuorumUpgrade>();

    scenario.next_tx(voter1);
    let add_voter_proposal = add_voter::new(&quorum_upgrade, new_voter, option::some(3));
    proposal::new(&quorum_upgrade, add_voter_proposal, vec_map::empty(), scenario.ctx());

    scenario.next_tx(voter1);
    proposal = scenario.take_shared<Proposal<AddVoter>>();
    assert!(proposal.quorum_reached(&quorum_upgrade) == false);
    let event = event::events_by_type<QuorumReachedEvent>();
    assert!(event.length() == 0);

    scenario.next_tx(voter2);
    proposal.vote(&quorum_upgrade, scenario.ctx());
    assert!(proposal.quorum_reached(&quorum_upgrade) == true);
    let event = event::events_by_type<QuorumReachedEvent>();
    assert!(event.length() == 1);
    assert!(event[0].proposal_id() == object::id(&proposal));
    transfer::public_share_object(quorum_upgrade);
    transfer::public_share_object(proposal);
    scenario.end();
}

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
fun new_proposal() {}

#[test]
fun invalid_new_proposal() {}

#[test]
fun vote_proposal() {}

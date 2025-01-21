// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::add_voter;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct AddVoter has store, drop {
    voter: address,
    new_required_votes: u64,
}

#[error]
const EInvalidNewVoter: vector<u8> = b"Voter already exists in the quorum";
#[error]
const ERequiredVotesZero: vector<u8> = b"Required votes must be greater than 0";
#[error]
const EInvalidRequiredVotes: vector<u8> =
    b"Required votes must be less than or equal to the number of voters";

public fun new(quorum_upgrade: &QuorumUpgrade, voter: address, new_required_votes: u64): AddVoter {
    assert!(!quorum_upgrade.voters().contains(&voter), EInvalidNewVoter);
    assert!(new_required_votes > 0, ERequiredVotesZero);
    assert!(new_required_votes <= quorum_upgrade.voters().size() as u64, EInvalidRequiredVotes);
    AddVoter { voter, new_required_votes }
}

public fun execute(proposal: Proposal<AddVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    let AddVoter {
        voter,
        new_required_votes,
    } = proposal.execute(quorum_upgrade);

    quorum_upgrade.add_voter(voter, new_required_votes);
}

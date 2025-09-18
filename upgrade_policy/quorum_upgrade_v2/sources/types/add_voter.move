// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::add_voter;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct AddVoter has drop, store {
    voter: address,
    new_required_votes: Option<u64>,
}

#[error]
const EInvalidNewVoter: vector<u8> = b"Voter already exists in the quorum";
#[error]
const ERequiredVotesZero: vector<u8> = b"Required votes must be greater than 0";
#[error]
const EInvalidRequiredVotes: vector<u8> =
    b"Required votes must be less than or equal to the number of voters";

public fun new(
    quorum_upgrade: &QuorumUpgrade,
    voter: address,
    new_required_votes: Option<u64>,
): AddVoter {
    let add_voter = AddVoter { voter, new_required_votes };
    assert_valid_proposal(&add_voter, quorum_upgrade);
    add_voter
}

public fun execute(proposal: Proposal<AddVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    let AddVoter {
        voter,
        mut new_required_votes,
    } = proposal.execute(quorum_upgrade);

    if (new_required_votes.is_some()) {
        quorum_upgrade.update_threshold(new_required_votes.extract());
    };
    quorum_upgrade.add_voter(voter);
}

public fun assert_valid_proposal(add_voter: &AddVoter, quorum_upgrade: &QuorumUpgrade) {
    let voter = add_voter.voter;
    let new_required_votes = add_voter.new_required_votes;
    assert!(!quorum_upgrade.voters().contains(&voter), EInvalidNewVoter);
    if (new_required_votes.is_some()) {
        let required_votes = new_required_votes.borrow();
        assert!(*required_votes > 0, ERequiredVotesZero);
        assert!(*required_votes <= quorum_upgrade.voters().length() as u64, EInvalidRequiredVotes);
    };
}

public fun voter(add_voter: &AddVoter): address {
    add_voter.voter
}

public fun required_votes(add_voter: &AddVoter): Option<u64> {
    add_voter.new_required_votes
}

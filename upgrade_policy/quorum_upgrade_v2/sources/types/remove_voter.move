// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::remove_voter;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct RemoveVoter has store, drop {
    voter: address,
    new_required_votes: Option<u64>,
}

// ~~~~~~~ Errors ~~~~~~~
#[error]
const EInvalidVoter: vector<u8> = b"Voter does not exist in the quorum";
#[error]
const ERequiredVotesZero: vector<u8> = b"Required votes must be greater than 0";
#[error]
const EInvalidRequiredVotes: vector<u8> =
    b"Required votes must be less than or equal to the number of voters";

public fun new(
    quorum_upgrade: &QuorumUpgrade,
    voter: address,
    mut new_required_votes: Option<u64>,
): RemoveVoter {
    assert!(quorum_upgrade.voters().contains(&voter), EInvalidVoter);
    if (new_required_votes.is_some()) {
        let required_votes = new_required_votes.extract();
        assert!(required_votes > 0, ERequiredVotesZero);
        assert!(required_votes <= quorum_upgrade.voters().size() as u64 - 1, EInvalidRequiredVotes);
    } else {
        assert!(
            quorum_upgrade.voters().size() - 1 >= quorum_upgrade.required_votes(),
            EInvalidRequiredVotes,
        );
    };

    RemoveVoter { voter, new_required_votes }
}

public fun execute(proposal: Proposal<RemoveVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    let RemoveVoter {
        voter,
        mut new_required_votes,
    } = proposal.execute(quorum_upgrade);

    if (new_required_votes.is_some()) {
        quorum_upgrade.update_required_votes(new_required_votes.extract());
    };

    quorum_upgrade.remove_voter(voter);
}

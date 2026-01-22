// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::update_threshold;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct UpdateThreshold has drop, store {
    new_required_votes: u64,
}

#[error]
const ERequiredVotesZero: vector<u8> = b"Required votes must be greater than 0";
#[error]
const EInvalidRequiredVotes: vector<u8> =
    b"Required votes must be less than or equal to the number of voters";

public fun new(quorum_upgrade: &QuorumUpgrade, new_required_votes: u64): UpdateThreshold {
    let update_threshold = UpdateThreshold { new_required_votes };
    assert_valid_proposal(&update_threshold, quorum_upgrade);
    update_threshold
}

public fun execute(proposal: Proposal<UpdateThreshold>, quorum_upgrade: &mut QuorumUpgrade) {
    let UpdateThreshold { new_required_votes } = proposal.execute(quorum_upgrade);
    quorum_upgrade.update_threshold(new_required_votes);
}

public fun assert_valid_proposal(
    update_threshold: &UpdateThreshold,
    quorum_upgrade: &QuorumUpgrade,
) {
    let new_required_votes = update_threshold.new_required_votes;
    assert!(new_required_votes > 0, ERequiredVotesZero);
    assert!(new_required_votes <= quorum_upgrade.voters().length() as u64, EInvalidRequiredVotes);
}

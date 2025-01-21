// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::update_required_votes;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct UpdateRequiredVotes has store, drop {
    new_required_votes: u64,
}

#[error]
const ERequiredVotesZero: vector<u8> = b"Required votes must be greater than 0";
#[error]
const EInvalidRequiredVotes: vector<u8> =
    b"Required votes must be less than or equal to the number of voters";

public fun new(quorum_upgrade: &QuorumUpgrade, new_required_votes: u64): UpdateRequiredVotes {
    assert!(new_required_votes > 0, ERequiredVotesZero);
    assert!(new_required_votes <= quorum_upgrade.voters().size() as u64, EInvalidRequiredVotes);
    UpdateRequiredVotes { new_required_votes }
}

public fun execute(proposal: Proposal<UpdateRequiredVotes>, quorum_upgrade: &mut QuorumUpgrade) {
    let UpdateRequiredVotes { new_required_votes } = proposal.execute(quorum_upgrade);
    quorum_upgrade.update_required_votes(new_required_votes);
}

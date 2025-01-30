// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::replace_voter;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct ReplaceVoter has drop, store {
    new_voter: address,
    old_voter: address,
}

#[error]
const EInvalidNewVoter: vector<u8> = b"Provided new voter already exists in the quorum";
#[error]
const EInvalidOldVoter: vector<u8> = b"Provided old voter does not exist in the quorum";

// Does/can validation happen here on the provided params
public fun new(
    quorum_upgrade: &QuorumUpgrade,
    new_voter: address,
    old_voter: address,
): ReplaceVoter {
    let replace_voter = ReplaceVoter { new_voter, old_voter };
    assert_valid_proposal(&replace_voter, quorum_upgrade);
    replace_voter
}

public fun execute(proposal: Proposal<ReplaceVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    let ReplaceVoter {
        new_voter,
        old_voter,
    } = proposal.execute(quorum_upgrade);

    quorum_upgrade.replace_voter(old_voter, new_voter);
}

public fun assert_valid_proposal(replace_voter: &ReplaceVoter, quorum_upgrade: &QuorumUpgrade) {
    let new_voter = replace_voter.new_voter;
    let old_voter = replace_voter.old_voter;
    assert!(quorum_upgrade.voters().contains(&old_voter), EInvalidOldVoter);
    assert!(!quorum_upgrade.voters().contains(&new_voter), EInvalidNewVoter);
}

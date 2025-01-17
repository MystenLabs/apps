// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::replace_voter;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct ReplaceVoter {
    new_voter: address,
    old_voter: address,
}

// Does/can validation happen here on the provided params
public fun new(
    quorum_upgrade: &QuorumUpgrade,
    new_voter: address,
    old_voter: address,
): ReplaceVoter {
    assert!(quorum_upgrade.voters().contains(&old_voter));
    assert!(!quorum_upgrade.voters().contains(&new_voter));
    ReplaceVoter { new_voter, old_voter }
}

public fun execute(proposal: Proposal<ReplaceVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    assert!(quorum_upgrade.voters().contains(&proposal.data().old_voter));
    assert!(!quorum_upgrade.voters().contains(&proposal.data().new_voter));

    let ReplaceVoter {
        new_voter,
        old_voter,
    } = proposal.execute(quorum_upgrade);

    quorum_upgrade.replace_voter(old_voter, new_voter);
}

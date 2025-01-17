// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::remove_voter;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct RemoveVoter {
    voter: address,
    new_required_votes: u64,
}

public fun new(
    quorum_upgrade: &QuorumUpgrade,
    voter: address,
    new_required_votes: u64,
): RemoveVoter {
    assert!(quorum_upgrade.voters().contains(&voter));
    assert!(new_required_votes >= quorum_upgrade.voters().size() - 1);
    RemoveVoter { voter, new_required_votes }
}

public fun execute(proposal: Proposal<RemoveVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    assert!(quorum_upgrade.voters().contains(&proposal.data().voter));
    assert!(quorum_upgrade.voters().size() - 1 >= quorum_upgrade.required_votes());

    let RemoveVoter {
        voter,
        new_required_votes,
    } = proposal.execute(quorum_upgrade);

    quorum_upgrade.remove_voter(voter, new_required_votes);
}

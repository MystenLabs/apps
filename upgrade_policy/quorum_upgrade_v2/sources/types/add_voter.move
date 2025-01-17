// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::add_voter;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct AddVoter has store {
    voter: address,
    new_required_votes: u64,
}

public fun new(quorum_upgrade: &QuorumUpgrade, voter: address, new_required_votes: u64): AddVoter {
    assert!(!quorum_upgrade.voters().contains(&voter));
    assert!(new_required_votes > 0);
    AddVoter { voter, new_required_votes }
}

public fun execute(proposal: Proposal<AddVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    assert!(!quorum_upgrade.voters().contains(&proposal.data().voter));

    let AddVoter {
        voter,
        new_required_votes,
    } = proposal.execute(quorum_upgrade);

    quorum_upgrade.add_voter(voter, new_required_votes);
}

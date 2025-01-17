// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::quorum_change;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct UpdateQuorum {
    new_required_votes: u64,
}

public fun new(quorum_upgrade: &QuorumUpgrade, new_required_votes: u64): UpdateQuorum {
    assert!(new_required_votes >= quorum_upgrade.voters().size());
    UpdateQuorum { new_required_votes }
}

public fun execute(proposal: Proposal<UpdateQuorum>, quorum_upgrade: &mut QuorumUpgrade) {
    let UpdateQuorum { new_required_votes } = proposal.execute(quorum_upgrade);
    quorum_upgrade.update_required_votes(new_required_votes);
}

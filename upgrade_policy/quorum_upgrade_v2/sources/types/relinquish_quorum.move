// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::relinquish_quorum;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;

public struct RelinquishQuorum has store, drop {
    new_owner: address,
}

// Does/can validation happen here on the provided params
public fun new(new_owner: address): RelinquishQuorum {
    RelinquishQuorum { new_owner }
}

public fun execute(proposal: Proposal<RelinquishQuorum>, quorum_upgrade: QuorumUpgrade) {
    let RelinquishQuorum {
        new_owner,
    } = proposal.execute(&quorum_upgrade);

    quorum_upgrade.relinquish_quorum(new_owner);
}

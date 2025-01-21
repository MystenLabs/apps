// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module quorum_upgrade_v2::upgrade;

use quorum_upgrade_v2::proposal::Proposal;
use quorum_upgrade_v2::quorum_upgrade::QuorumUpgrade;
use sui::package::UpgradeTicket;

public struct Upgrade has store, drop {
    digest: vector<u8>,
}

public fun new(digest: vector<u8>): Upgrade {
    Upgrade { digest }
}

public fun execute(proposal: Proposal<Upgrade>, quorum_upgrade: &mut QuorumUpgrade): UpgradeTicket {
    let Upgrade { digest } = proposal.execute(quorum_upgrade);
    quorum_upgrade.authorize_upgrade(digest)
}

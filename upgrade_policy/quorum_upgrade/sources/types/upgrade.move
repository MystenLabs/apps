module quorum_upgrade_policy::upgrade;

use quorum_upgrade_policy::proposal::Proposal;
use quorum_upgrade_policy::quorum_upgrade_v2::QuorumUpgrade;
use sui::package::UpgradeTicket;

public struct Upgrade has copy, drop {
    digest: vector<u8>,
}

public fun new(digest: vector<u8>): Upgrade {
    Upgrade { digest }
}

public fun execute(proposal: Proposal<Upgrade>, quorum_upgrade: &mut QuorumUpgrade): UpgradeTicket {
    let digest = proposal.data().digest;

    proposal.execute(quorum_upgrade);

    let ticket = quorum_upgrade.authorize_upgrade(digest);

    ticket
}

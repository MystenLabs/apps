module quorum_upgrade_policy::upgrade;

use quorum_upgrade_policy::quorum_upgrade_policy_v2::{Proposal, QuorumUpgrade};

public struct Upgrade has copy, drop {
    digest: vector<u8>,
}

public fun new(digest: vector<u8>): Upgrade {
    Upgrade { digest }
}

public fun execute(proposal: Proposal<Upgrade>, quorum_upgrade: &QuorumUpgrade) {
    assert!(proposal.quorum_reached(quorum_upgrade));
    let digest = proposal.data().digest;

    // TODO: Execute upgrade

    // delete proposal
}

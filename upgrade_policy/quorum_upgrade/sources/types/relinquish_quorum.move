module quorum_upgrade_policy::relinquish_quorum;

use quorum_upgrade_policy::quorum_upgrade_policy_v2::{Proposal, QuorumUpgrade};

public struct RelinquishQuorum has copy, drop {
    new_owner: address,
}

// Does/can validation happen here on the provided params
public fun new(new_owner: address): RelinquishQuorum {
    RelinquishQuorum { new_owner }
}

public fun execute(proposal: &Proposal<RelinquishQuorum>, quorum_upgrade: QuorumUpgrade) {
    assert!(proposal.quorum_reached(&quorum_upgrade));

    let RelinquishQuorum {
        new_owner,
    } = proposal.data();

    quorum_upgrade.relinquish_quorum(new_owner);

    // delete proposal
}

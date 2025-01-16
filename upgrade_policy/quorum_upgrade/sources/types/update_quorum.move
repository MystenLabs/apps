module quorum_upgrade_policy::quorum_change;

use quorum_upgrade_policy::proposal::Proposal;
use quorum_upgrade_policy::quorum_upgrade_v2::QuorumUpgrade;

public struct UpdateQuorum has copy, drop {
    new_required_votes: u64,
}

public fun new(new_required_votes: u64): UpdateQuorum {
    UpdateQuorum { new_required_votes }
}

public fun execute(proposal: Proposal<UpdateQuorum>, quorum_upgrade: &mut QuorumUpgrade) {
    let new_required_votes = proposal.data().new_required_votes;

    proposal.execute(quorum_upgrade);

    quorum_upgrade.update_required_votes(new_required_votes);
}

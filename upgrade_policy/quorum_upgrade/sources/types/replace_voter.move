module quorum_upgrade_policy::replace_voter;

use quorum_upgrade_policy::proposal::Proposal;
use quorum_upgrade_policy::quorum_upgrade_v2::QuorumUpgrade;

public struct ReplaceVoter has copy, drop {
    new_voter: address,
    old_voter: address,
}

// Does/can validation happen here on the provided params
public fun new(new_voter: address, old_voter: address): ReplaceVoter {
    ReplaceVoter { new_voter, old_voter }
}

public fun execute(proposal: Proposal<ReplaceVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    assert!(quorum_upgrade.voters().contains(&proposal.data().old_voter));
    assert!(!quorum_upgrade.voters().contains(&proposal.data().new_voter));

    let ReplaceVoter {
        new_voter,
        old_voter,
    } = proposal.data();

    proposal.execute(quorum_upgrade);

    quorum_upgrade.replace_voter(old_voter, new_voter);
}

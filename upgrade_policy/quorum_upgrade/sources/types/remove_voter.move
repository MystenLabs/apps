module quorum_upgrade_policy::remove_voter;

use quorum_upgrade_policy::proposal::Proposal;
use quorum_upgrade_policy::quorum_upgrade_v2::QuorumUpgrade;

public struct RemoveVoter has copy, drop {
    voter: address,
    new_required_votes: u64,
}

// Does/can validation happen here on the provided params
public fun new(voter: address, new_required_votes: u64): RemoveVoter {
    RemoveVoter { voter, new_required_votes }
}

public fun execute(proposal: Proposal<RemoveVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    assert!(quorum_upgrade.voters().contains(&proposal.data().voter));
    assert!(quorum_upgrade.voters().size() - 1 >= quorum_upgrade.required_votes());

    let RemoveVoter {
        voter,
        new_required_votes,
    } = proposal.data();

    proposal.execute(quorum_upgrade);

    quorum_upgrade.remove_voter(voter, new_required_votes);
}

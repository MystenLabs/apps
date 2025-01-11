module quorum_upgrade_policy::add_voter;

use quorum_upgrade_policy::quorum_upgrade_policy_v2::{Proposal, QuorumUpgrade};

public struct AddVoter has copy, drop {
    voter: address,
    new_required_votes: u64,
}

// Does/can validation happen here on the provided params
public fun new(voter: address, new_required_votes: u64): AddVoter {
    AddVoter { voter, new_required_votes }
}

public fun execute(proposal: &Proposal<AddVoter>, quorum_upgrade: &mut QuorumUpgrade) {
    assert!(proposal.quorum_reached(quorum_upgrade));
    assert!(!quorum_upgrade.voters().contains(&proposal.data().voter));

    let AddVoter {
        voter,
        new_required_votes,
    } = proposal.data();

    quorum_upgrade.add_voter(voter, new_required_votes);

    // delete proposal
}

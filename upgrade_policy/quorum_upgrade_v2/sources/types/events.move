module quorum_upgrade_v2::events;

use sui::event;

public struct VoteCastEvent has copy, drop {
    proposal_id: ID,
    total_votes: u64,
}

public struct ProposalDeletedEvent has copy, drop {
    proposal_id: ID,
}

public struct ProposalExecutedEvent has copy, drop {
    proposal_id: ID,
}

public struct VoterAddedEvent has copy, drop {
    quorum_upgrade_id: ID,
    voter: address,
}

public struct VoterRemovedEvent has copy, drop {
    proposal_id: ID,
    voter: address,
}

public struct VoterReplacedEvent has copy, drop {
    proposal_id: ID,
    old_voter: address,
    new_voter: address,
}

public struct RequiredVotesChangedEvent has copy, drop {
    proposal_id: ID,
    new_required_votes: u64,
}

public struct QuorumRelinquishedEvent has copy, drop {
    proposal_id: ID,
}

public(package) fun emit_vote_cast_event(proposal_id: ID, total_votes: u64) {
    event::emit(VoteCastEvent {
        proposal_id: proposal_id,
        total_votes: total_votes,
    });
}

public(package) fun emit_proposal_deleted_event(proposal_id: ID) {
    event::emit(ProposalDeletedEvent {
        proposal_id: proposal_id,
    });
}

public(package) fun emit_proposal_executed_event(proposal_id: ID) {
    event::emit(ProposalExecutedEvent {
        proposal_id: proposal_id,
    });
}

public(package) fun emit_voter_added_event(quorum_upgrade_id: ID, voter: address) {
    event::emit(VoterAddedEvent {
        quorum_upgrade_id: quorum_upgrade_id,
        voter: voter,
    });
}

public(package) fun emit_voter_removed_event(proposal_id: ID, voter: address) {
    event::emit(VoterRemovedEvent {
        proposal_id: proposal_id,
        voter: voter,
    });
}

public(package) fun emit_voter_replaced_event(
    proposal_id: ID,
    old_voter: address,
    new_voter: address,
) {
    event::emit(VoterReplacedEvent {
        proposal_id: proposal_id,
        old_voter: old_voter,
        new_voter: new_voter,
    });
}

public(package) fun emit_required_votes_changed_event(proposal_id: ID, new_required_votes: u64) {
    event::emit(RequiredVotesChangedEvent {
        proposal_id: proposal_id,
        new_required_votes: new_required_votes,
    });
}

public(package) fun emit_quorum_relinquished_event(proposal_id: ID) {
    event::emit(QuorumRelinquishedEvent {
        proposal_id: proposal_id,
    });
}

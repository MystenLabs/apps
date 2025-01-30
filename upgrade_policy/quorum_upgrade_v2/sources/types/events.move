module quorum_upgrade_v2::events;

use sui::event;

public struct VoteCastEvent has copy, drop {
    proposal_id: ID,
    voter: address,
}

public struct VoteRemovedEvent has copy, drop {
    proposal_id: ID,
    voter: address,
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

public struct QuorumReachedEvent has copy, drop {
    proposal_id: ID,
}

public struct VoterReplacedEvent has copy, drop {
    proposal_id: ID,
    old_voter: address,
    new_voter: address,
}

public struct ThresholdUpdatedEvent has copy, drop {
    proposal_id: ID,
    new_required_votes: u64,
}

public struct QuorumRelinquishedEvent has copy, drop {
    proposal_id: ID,
}

public(package) fun emit_vote_cast_event(proposal_id: ID, voter: address) {
    event::emit(VoteCastEvent {
        proposal_id,
        voter,
    });
}

public(package) fun emit_vote_removed_event(proposal_id: ID, voter: address) {
    event::emit(VoteRemovedEvent {
        proposal_id,
        voter,
    });
}

public(package) fun emit_quorum_reached_event(proposal_id: ID) {
    event::emit(QuorumReachedEvent {
        proposal_id,
    });
}

public(package) fun emit_proposal_deleted_event(proposal_id: ID) {
    event::emit(ProposalDeletedEvent {
        proposal_id,
    });
}

public(package) fun emit_proposal_executed_event(proposal_id: ID) {
    event::emit(ProposalExecutedEvent {
        proposal_id,
    });
}

public(package) fun emit_voter_added_event(quorum_upgrade_id: ID, voter: address) {
    event::emit(VoterAddedEvent {
        quorum_upgrade_id,
        voter,
    });
}

public(package) fun emit_voter_removed_event(proposal_id: ID, voter: address) {
    event::emit(VoterRemovedEvent {
        proposal_id,
        voter,
    });
}

public(package) fun emit_voter_replaced_event(
    proposal_id: ID,
    old_voter: address,
    new_voter: address,
) {
    event::emit(VoterReplacedEvent {
        proposal_id,
        old_voter,
        new_voter,
    });
}

public(package) fun emit_threshold_updated_event(proposal_id: ID, new_required_votes: u64) {
    event::emit(ThresholdUpdatedEvent {
        proposal_id,
        new_required_votes,
    });
}

public(package) fun emit_quorum_relinquished_event(proposal_id: ID) {
    event::emit(QuorumRelinquishedEvent {
        proposal_id: proposal_id,
    });
}

#[test_only]
public fun proposal_id(quorum_reached_event: &QuorumReachedEvent): ID {
    quorum_reached_event.proposal_id
}

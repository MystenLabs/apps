// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Simple upgrade policy that requires a `k` out of `n` quorum in order to perform
/// a proposed upgrade.
///
/// This policy is created with a call to `quorum_upgrade_policy::new` providing
/// the `UpgradeCap` of the package to be controlled by the policy, the `k` value
/// (number of votes, quorum to be reached for the upgrade to be allowed) and the list of
/// `address`es allowed to vote. The `address`es provided will receive
/// a `VotingCap` that allows them to vote for a proposed upgrade.
/// This policy can be created at any point in time during the lifetime of the original
/// package upgrade cap.
/// The `QuorumUpgradeCap` received from the call to `quorum_upgrade_policy::new` will
/// be used when proposing an upgrade and when authorizing that upgrade.
/// Given that it is created with the original `UpgradeCap`, it is returned to the owner
/// of that capability, typically the publisher of the original package.
/// That impies the owner of the `UpgradeCap` is the only one that can propose and
/// authorize upgrades.
/// Considering that the `QuorumUpgradeCap` is both `key` and `store` the owner can decide
/// on alternative ways to offer that capability to other parties.
/// As expected, however, the capability should be reasonably protected and secured.
///
/// An upgrade is proposed via `quorum_upgrade_policy::propose_upgrade` and saved as
/// a shared object. As such it can be freely accessed. That instance will be used
/// by both voters of the upgrade and the publisher of the upgrade.
/// The proposer of an upgrade provides the digest of the upgrade that is saved with
/// the proposal. The idea is that the proposer will provide the compilable source code
/// to all voters, which in turn will verify the digest and, thus, the source code.
///
/// Voters can then vote for the upgrade via `quorum_upgrade_policy::vote` providing
/// the `ProposedUpgrade` and their `VotingCap`.
///
/// Once the quorum is reached the proposer can authorize the upgrade. An attempt to
/// authourize an upgrade before the quorum is reached will fail.
///
/// Events are emitted to track the main operations on the proposal.
/// A proposed upgrade lifetime is tracked via the 4 events:
/// `UpgradeProposed`, `UpgradeVoted` and `UpgradePerformed` or `UpgradeDestroyed`.
///
/// Multiple upgrades can be live at the same time. That is not the expected behavior
/// but there are no restrictions to the number of upgrades open at any point in time.
/// When that happens the first upgrade executed "wins" and subsequent attempt to
/// authorize an upgrade will fail as the version will not match any longer.
///
/// Notice:
/// there are several upgrades to this policy that will be provided shortly and will
/// help with the management of the policy:
/// - the ability to restrict the upgrade as with normal packages (e.g. additive only,
/// dependency only or immutable) and whether to do that via voting or not is being
/// discussed
/// - the ability to transfer `VotingCap` instances to other addresses will likely
/// be controlled by voting and it is an important feature to add
/// - the ability to change the quorum (k) and the list of allowed voters (n) is
/// under consideration
/// - the creation and usage of a `Ballot` to vote for the upgrade is also being
/// discussed. The ballot will be transferable and an easy way to relate to a proposal
module quorum_upgrade_policy::quorum_upgrade_policy {
    use quorum_upgrade_v2::quorum_upgrade;
    use sui::event;
    use sui::package::{Self, UpgradeCap, UpgradeTicket, UpgradeReceipt};
    use sui::vec_set::{Self, VecSet};
    use sui::dynamic_field::{Self as df};
    use sui::vec_map::{VecMap};
    use std::string;

    /// The capability controlling the upgrade.
    /// Initialized with `new` is returned to the caller to be stored as desired.
    /// From this point on every upgrade is performed via this policy.
    public struct QuorumUpgradeCap has key, store {
        id: UID,
        /// Upgrade cap of the package controlled by this policy.
        upgrade_cap: UpgradeCap,
        /// Number of votes (quorum) required for the upgrade to be allowed.
        required_votes: u64,
        /// Allowed voters.
        voters: VecSet<address>,
        /// Voting caps issued.
        voter_caps: VecSet<ID>,
    }

    /// Capability to vote an upgrade.
    /// Sent to each registered address when a new upgrade is created.
    /// Receiving parties will use the capability to vote for the upgrade.
    public struct VotingCap has key {
        id: UID,
        /// The original address the capability was sent to.
        owner: address,
        /// The ID of the `QuorumUpgradeCap` this capability refers to.
        upgrade_cap: ID,
        /// The count of transfers this capability went through.
        /// It is informational only and can be used to track transfers of
        /// voter capability instances.
        transfers_count: u64,
        /// The number of votes issued by this voter.
        votes_issued: u64,
    }

    /// A proposed upgrade that is going through voting.
    /// `ProposedUpgrade` instances are shared objects that will be passed as
    /// an argument, together with a `VotingCap`, when voting.
    /// It's possible to have multiple proposed upgrades at the same time and
    /// the first successful upgrade will obsolete all the others, given
    /// an attempt to upgrade with a "concurrent" one will fail because of
    /// versioning.
    public struct ProposedUpgrade has key {
        id: UID,
        /// The ID of the `QuorumUpgradeCap` that this vote was initiated from.
        upgrade_cap: ID,
        /// The address requesting permission to perform the upgrade.
        /// This is the sender of the transaction that proposes and
        /// performs the upgrade.
        proposer: address,
        /// The digest of the bytecode that the package will be upgraded to.
        digest: vector<u8>,
        /// The current voters that have accepted the upgrade.
        current_voters: VecSet<ID>,
    }

    //
    // Events to track history and progress of upgrades
    //

    /// A new proposal for an upgrade.
    public struct UpgradeProposed has copy, drop {
        /// The instance of the quorum upgrade policy.
        upgrade_cap: ID,
        /// The ID of the proposal (`ProposedUpgrade` instance).
        proposal: ID,
        /// Digest of the proposal.
        digest: vector<u8>,
        /// The address (sender) of the proposal.
        proposer: address,
        /// Allowed voters.
        voters: VecSet<address>,
    }

    /// A given proposal was voted.
    public struct UpgradeVoted has copy, drop {
        /// The ID of the proposal (`ProposedUpgrade` instance).
        proposal: ID,
        /// Digest of the proposal.
        digest: vector<u8>,
        /// The ID of the voter (VotingCap instance).
        voter: ID,
        /// The signer of the transaction that voted.
        signer: address,
    }

    /// A succesful upgrade.
    public struct UpgradePerformed has copy, drop {
        /// The instance of the quorum upgrade policy.
        upgrade_cap: ID,
        /// the ID of the proposal (`ProposedUpgrade` instance).
        proposal: ID,
        /// digest of the proposal.
        digest: vector<u8>,
        /// proposer of the upgrade.
        proposer: address,
    }

    /// A proposal is destroyed.
    public struct UpgradeDestroyed has copy, drop {
        /// The instance of the quorum upgrade policy.
        upgrade_cap: ID,
        /// The ID of the proposal (`ProposedUpgrade` instance).
        proposal: ID,
        /// Digest of the proposal.
        digest: vector<u8>,
        /// Proposer of the upgrade.
        proposer: address,
    }

    /// struct for optional upgrade metadata
    public struct UpgradeMetadata has store, copy, drop {}

    /// Allowed voters must in the [1, 100] range.
    const EAllowedVotersError: u64 = 0;
    /// Required votes must be less than allowed voters.
    const ERequiredVotesError: u64 = 1;
    /// An upgrade was issued already, and the operation requested failed.
    const EAlreadyIssued: u64 = 2;
    /// The given `VotingCap` is not for the given `ProposedUpgrade`
    const EInvalidVoterForUpgrade: u64 = 3;
    /// The given capability owner already voted.
    const EAlreadyVoted: u64 = 4;
    /// Not enough votes to perform the upgrade.
    const ENotEnoughVotes: u64 = 5;
    /// The operation required the signer to be the same as the upgrade proposer.
    const ESignerMismatch: u64 = 6;
    /// Proposal (`QuorumUpgradeCap`) and upgrade (`ProposedUpgrade`) do not match.
    const EInvalidProposalForUpgrade: u64 = 7;
    /// Invalid address for adding metadata
    const EInvalidProposerForMetadata: u64 = 8;
    /// Metadata already exists for the proposal
    const EMetadataAlreadyExists: u64 = 9;

    /// Create a `QuorumUpgradeCap` given an `UpgradeCap`.
    /// The returned instance is the only and exclusive controller of upgrades.
    /// The `k` (`required_votes`) out of `n` (length of `voters`) is set up
    /// at construction time and it is immutable.
    /// The `voters` will receive a `VotingCap` that allows them to vote.
    public fun new(
        upgrade_cap: UpgradeCap,
        required_votes: u64,
        voters: VecSet<address>,
        ctx: &mut TxContext,
    ): QuorumUpgradeCap {
        // currently the allowed voters is limited to 100 and the number of
        // required votes must be bigger than 0 and less or equal than the number of voters
        assert!(voters.size() > 0, EAllowedVotersError);
        assert!(voters.size() <= 100, EAllowedVotersError);
        assert!(required_votes > 0, ERequiredVotesError);
        assert!(required_votes <= voters.size(), ERequiredVotesError);

        // upgrade cap id
        let cap_uid = object::new(ctx);
        let cap_id = object::uid_to_inner(&cap_uid);

        let mut voter_caps: VecSet<ID> = vec_set::empty();
        let voter_addresses = voters.keys();
        let mut voter_idx = voter_addresses.length();
        while (voter_idx > 0) {
            voter_idx = voter_idx - 1;
            let voter_address = voter_addresses[voter_idx];
            let voter_uid = object::new(ctx);
            let voter_id = object::uid_to_inner(&voter_uid);
            transfer::transfer(
                VotingCap {
                    id: voter_uid,
                    owner: voter_address,
                    upgrade_cap: cap_id,
                    transfers_count: 0,
                    votes_issued: 0,
                },
                voter_address,
            );
            voter_caps.insert(voter_id);
        };

        QuorumUpgradeCap {
            id: cap_uid,
            upgrade_cap,
            required_votes,
            voters,
            voter_caps,
        }
    }

    public fun migrate_quorum_to_v2(cap: QuorumUpgradeCap, ctx: &mut TxContext) {
        let QuorumUpgradeCap {
            id,
            upgrade_cap,
            required_votes,
            voters,
            voter_caps: _voter_caps,
        } = cap;
        quorum_upgrade::new(upgrade_cap, required_votes, voters, ctx);
        id.delete();
    }

    /// Propose an upgrade.
    /// The `digest` of the proposed upgrade is provided to identify the upgrade.
    /// The proposer is the sender of the transaction and must be the signer
    /// of the commit transaction as well.
    #[allow(lint(share_owned))]
    public fun propose_upgrade(
        cap: &QuorumUpgradeCap,
        digest: vector<u8>,
        ctx: &mut TxContext,
    ) {
        transfer::share_object(internal_propose_upgrade(cap, digest, ctx))
    }

    /// V2 of propose_upgrade, returns ProposedUpgrade object which can be used
    /// in add_metadata function to optionally add metadata.
    /// Must be used to call share_upgrade_object to share proposal with voters.
    public fun create_upgrade(
        cap: &QuorumUpgradeCap,
        digest: vector<u8>,
        ctx: &mut TxContext,
    ): ProposedUpgrade {
        internal_propose_upgrade(cap, digest, ctx)
    }

    public fun add_metadata(
        upgrade: &mut ProposedUpgrade,
        metadata_map: VecMap<string::String, string::String>,
        ctx: &mut TxContext,
    ) {
        assert!(upgrade.proposer == ctx.sender(), EInvalidProposerForMetadata);
        assert!(!df::exists_with_type<UpgradeMetadata, VecMap<string::String, string::String>>(&upgrade.id, UpgradeMetadata {}), EMetadataAlreadyExists);
        df::add(&mut upgrade.id, UpgradeMetadata {}, metadata_map);
    }

    /// Share the upgrade object created by create_upgrade
    #[allow(lint(share_owned))]
    public fun share_upgrade_object(
        upgrade: ProposedUpgrade
    ) {
        transfer::share_object(upgrade)
    }

    /// Vote in favor of an upgrade, aborts if the voter is not for the proposed
    /// upgrade or if they voted already, or if the upgrade was already performed.
    public fun vote(
        proposal: &mut ProposedUpgrade,
        voter: &mut VotingCap,
        ctx: &TxContext,
    ) {
        assert!(proposal.proposer != @0x0, EAlreadyIssued);
        assert!(proposal.upgrade_cap == voter.upgrade_cap, EInvalidVoterForUpgrade);
        let voter_id = object::id(voter);
        assert!(
            !proposal.current_voters.contains(&voter_id),
            EAlreadyVoted,
        );
        proposal.current_voters.insert(voter_id);
        voter.votes_issued = voter.votes_issued + 1;

        event::emit(UpgradeVoted {
            proposal: object::id(proposal),
            digest: proposal.digest,
            voter: voter_id,
            signer: ctx.sender(),
        });
    }

    /// Issue an `UpgradeTicket` for the upgrade being voted on. Aborts if
    /// there are not enough votes yet, or if the upgrade was already performed.
    /// The signer of the transaction must be the same as the one proposing the
    /// upgrade.
    public fun authorize_upgrade(
        cap: &mut QuorumUpgradeCap,
        proposal: &mut ProposedUpgrade,
        ctx: &TxContext,
    ): UpgradeTicket {
        authorize(cap, proposal, ctx)
    }

    public fun authorize_upgrade_and_cleanup(
        cap: &mut QuorumUpgradeCap,
        mut proposal_obj: ProposedUpgrade,
        ctx: &TxContext,
    ): UpgradeTicket {
        let upgrade_ticket = authorize(cap, &mut proposal_obj, ctx);

        let ProposedUpgrade {
            id,
            upgrade_cap: _,
            proposer: _,
            digest: _,
            current_voters: _,
        } = proposal_obj;
        object::delete(id);
        upgrade_ticket
    }

    /// Finalize the upgrade to produce the given receipt.
    public fun commit_upgrade(
        cap: &mut QuorumUpgradeCap,
        receipt: UpgradeReceipt,
    ) {
        package::commit_upgrade(&mut cap.upgrade_cap, receipt)
    }

    /// Destroy (and so discard) an existing proposed upgrade.
    /// The signer of the transaction must be the same address that proposed the
    /// upgrade.
    public fun destroy_proposed_upgrade(proposed_upgrade: ProposedUpgrade, ctx: &TxContext) {
        let proposal = object::id(&proposed_upgrade);
        let ProposedUpgrade {
            id,
            upgrade_cap,
            proposer,
            digest,
            current_voters: _,
        } = proposed_upgrade;
        assert!(proposer == ctx.sender(), ESignerMismatch);
        event::emit(UpgradeDestroyed {
            upgrade_cap,
            proposal,
            digest,
            proposer,
        });
        object::delete(id);
    }

    //
    // Accessors
    //

    /// Get the `UpgradeCap` of the package protected by the policy.
    public fun upgrade_cap(cap: &QuorumUpgradeCap): &UpgradeCap {
        &cap.upgrade_cap
    }

    /// Get the number of required votes for an upgrade to be valid.
    public fun required_votes(cap: &QuorumUpgradeCap): u64 {
        cap.required_votes
    }

    /// Get the allowed voters for the policy.
    public fun voters(cap: &QuorumUpgradeCap): &VecSet<address> {
        &cap.voters
    }

    /// Get the ID of the policy associated to the proposal.
    public fun proposal_for(proposal: &ProposedUpgrade): ID {
        proposal.upgrade_cap
    }

    /// Get the upgrade proposer.
    public fun proposer(proposal: &ProposedUpgrade): address {
        proposal.proposer
    }

    /// Get the digest of the proposed upgrade.
    public fun digest(proposal: &ProposedUpgrade): &vector<u8> {
        &proposal.digest
    }

    /// Get the current accepted votes for the given proposal.
    public fun current_voters(proposal: &ProposedUpgrade): &VecSet<ID> {
        &proposal.current_voters
    }

    /// retrieve metadata from ProposedUpgrade object in v2
    public fun metadata(
        proposal: &ProposedUpgrade,
    ): VecMap<string::String, string::String> {
        *df::borrow(&proposal.id, UpgradeMetadata {})
    }

    /// propose upgrade helper function
    fun internal_propose_upgrade(
        cap: &QuorumUpgradeCap,
        digest: vector<u8>,
        ctx: &mut TxContext,
    ): ProposedUpgrade {
        let cap_id = object::id(cap);
        let proposal_uid = object::new(ctx);
        let proposal_id = object::uid_to_inner(&proposal_uid);

        let proposer = ctx.sender();

        event::emit(UpgradeProposed {
            upgrade_cap: cap_id,
            proposal: proposal_id,
            digest,
            proposer,
            voters: cap.voters,
        });

        ProposedUpgrade {
            id: proposal_uid,
            upgrade_cap: cap_id,
            proposer,
            digest,
            current_voters: vec_set::empty(),
        }
    }

    /// authorize upgrade helper function
    fun authorize(
        cap: &mut QuorumUpgradeCap,
        proposal: &mut ProposedUpgrade,
        ctx: &TxContext,
    ): UpgradeTicket {
        assert!(proposal.upgrade_cap == object::id(cap), EInvalidProposalForUpgrade);
        assert!(
            proposal.current_voters.size() >= cap.required_votes,
            ENotEnoughVotes,
        );
        assert!(proposal.proposer != @0x0, EAlreadyIssued);

        // assert the signer is the proposer and the upgrade has not happened yet
        let signer = ctx.sender();
        assert!(proposal.proposer == signer, ESignerMismatch);
        proposal.proposer = @0x0;

        event::emit(UpgradePerformed {
            upgrade_cap: proposal.upgrade_cap,
            proposal: object::id(proposal),
            digest: proposal.digest,
            proposer: signer,
        });

        df::remove_if_exists<UpgradeMetadata, VecMap<string::String, string::String>>(&mut proposal.id, UpgradeMetadata {});
        let policy = package::upgrade_policy(&cap.upgrade_cap);
        package::authorize_upgrade(
            &mut cap.upgrade_cap,
            policy,
            proposal.digest,
        )
    }

    #[test_only]
    /// Make the package immutable by destroying the quorum upgrade cap and the
    /// underlying upgrade cap.
    public fun make_immutable(cap: QuorumUpgradeCap) {
        let QuorumUpgradeCap {
            id,
            upgrade_cap,
            required_votes: _,
            voters: _,
            voter_caps: _,
        } = cap;
        object::delete(id);
        package::make_immutable(upgrade_cap);
    }

}

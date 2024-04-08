// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module quorum_upgrade_policy::quorum_upgrade_policy_test {
    use quorum_upgrade_policy::quorum_upgrade_policy::{Self, QuorumUpgradeCap, ProposedUpgrade, VotingCap};
    use sui::address::from_u256;
    use sui::object::id_from_address as id;
    use sui::package;
    use sui::vec_set::{Self, VecSet};
    use sui::test_scenario::{Self as test, Scenario, ctx};
    use sui::vec_map::{Self, VecMap};
    use std::string;

    const ADDRESS_1: address = @0x1;
    const ADDRESS_2: address = @0x2;

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ERequiredVotesError)]
    fun quorum_upgrade_too_many_required_votes() {
        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(30, 5, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAllowedVotersError)]
    fun quorum_upgrade_too_many_voters() {
        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(80, 101, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAllowedVotersError)]
    fun quorum_upgrade_too_few_voters() {
        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(1, 0, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ERequiredVotesError)]
    fun quorum_upgrade_too_few_required_votes() {
        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(0, 10, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun quorum_upgrade_voters_ok() {
        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(80, 80, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(100, 100, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(2, 2, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(70, 100, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(30, 50, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(1, 2, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun quorum_upgrade_propose_upgrade_ok() {
        let mut test = test::begin(ADDRESS_1);
        let digest: vector<u8> = x"0123456789";
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);

        test.next_tx(ADDRESS_1);
        quorum_upgrade_policy::propose_upgrade(&quorum_upgrade_cap, digest, ctx(&mut test));

        test.next_tx(ADDRESS_1);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EInvalidProposalForUpgrade)]
    fun quorum_upgrade_authorize_upgrade_bad_cap() {
        let mut test = test::begin(ADDRESS_1);
        let digest: vector<u8> = x"0123456789";
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);

        test.next_tx(ADDRESS_1);
        quorum_upgrade_policy::propose_upgrade(&quorum_upgrade_cap, digest, ctx(&mut test));

        test.next_tx(ADDRESS_1);
        let mut quorum_upgrade_cap1 = get_quorum_upgrade_cap(6, 10, &mut test);
        let mut proposal = test.take_shared<ProposedUpgrade>();
        let ticket = quorum_upgrade_policy::authorize_upgrade(
            &mut quorum_upgrade_cap1, 
            &mut proposal, 
            ctx(&mut test),
        );
        let receipt = package::test_upgrade(ticket);
        quorum_upgrade_policy::commit_upgrade(&mut quorum_upgrade_cap, receipt);
        test::return_shared(proposal);

        test.next_tx(ADDRESS_1);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap1);

        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ENotEnoughVotes)]
    fun quorum_upgrade_authorize_upgrade_not_enough_votes() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ENotEnoughVotes)]
    fun quorum_upgrade_authorize_upgrade_not_enough_votes_1() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ENotEnoughVotes)]
    fun quorum_upgrade_authorize_upgrade_not_enough_votes_2() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(2, 2, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ENotEnoughVotes)]
    fun quorum_upgrade_authorize_upgrade_not_enough_votes_3() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(6, 10, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x105, &mut test);
        vote(@0x106, &mut test);
        vote(@0x102, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ESignerMismatch)]
    fun quorum_upgrade_authorize_upgrade_bad_signer() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        let mut quorum_upgrade_cap_1 = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_2, &quorum_upgrade_cap_1, digest, &mut test);

        vote(@0x100, &mut test);
        vote(@0x103, &mut test);
        vote(@0x101, &mut test);
        vote(@0x102, &mut test);

        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap_1, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap_1);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EInvalidProposalForUpgrade)]
    fun quorum_upgrade_authorize_upgrade_bad_voter_cap() {
        let digest: vector<u8> = x"0123456789";
        let digest1: vector<u8> = x"9876543210";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        let quorum_upgrade_cap_1 = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_2, &quorum_upgrade_cap_1, digest1, &mut test);

        vote(@0x102, &mut test);
        vote(@0x103, &mut test);
        vote(@0x101, &mut test);

        perform_upgrade(ADDRESS_2, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap_1);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAlreadyIssued)]
    fun quorum_upgrade_authorize_upgrade_already_issued() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);

        vote(@0x100, &mut test);
        vote(@0x103, &mut test);
        vote(@0x104, &mut test);

        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAlreadyIssued)]
    fun quorum_upgrade_vote_already_issued() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);

        vote(@0x100, &mut test);
        vote(@0x103, &mut test);
        vote(@0x104, &mut test);

        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        vote(@0x101, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EInvalidVoterForUpgrade)]
    fun quorum_upgrade_bad_voter() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        test.next_tx(@0x100);
        // get the voter cap and use it over the next upgrade and proposal
        let mut voter_cap = test::take_from_address<VotingCap>(&test, @0x100);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        test.next_tx(@0x100);
        let mut proposal = test.take_shared<ProposedUpgrade>();
        quorum_upgrade_policy::vote(&mut proposal, &mut voter_cap, ctx(&mut test));
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test::return_shared(proposal);
        test::return_to_address(@0x100, voter_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAlreadyVoted)]
    fun quorum_upgrade_vote_twice() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);

        vote(@0x100, &mut test);
        vote(@0x100, &mut test);

        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAlreadyIssued)]
    fun quorum_upgrade_upgrade_already_issued() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        vote(@0x102, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun quorum_upgrade_perform_upgrade_ok() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(ADDRESS_2);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(8, 10, &mut test);
        propose_upgrade(ADDRESS_2, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        vote(@0x105, &mut test);
        vote(@0x106, &mut test);
        vote(@0x107, &mut test);
        vote(@0x108, &mut test);
        vote(@0x109, &mut test);
        perform_upgrade(ADDRESS_2, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x3);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 9, &mut test);
        propose_upgrade(@0x3, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        vote(@0x105, &mut test);
        perform_upgrade(@0x3, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x4);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(1, 100, &mut test);
        propose_upgrade(@0x4, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x140, &mut test);
        perform_upgrade(@0x4, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x5);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        propose_upgrade(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x103, &mut test); 
        vote(@0x100, &mut test); 
        vote(@0x102, &mut test); 
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun quorum_upgrade_create_upgrade_ok() {
        let mut test = test::begin(ADDRESS_1);
        let digest: vector<u8> = x"0123456789";
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);

        test.next_tx(ADDRESS_1);
        let proposed_upgrade = quorum_upgrade_policy::create_upgrade(&quorum_upgrade_cap, digest, ctx(&mut test));
        quorum_upgrade_policy::share_upgrade_object(proposed_upgrade);

        test.next_tx(ADDRESS_1);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EInvalidProposalForUpgrade)]
    fun quorum_upgrade_authorize_upgrade_v2_bad_cap() {
        let mut test = test::begin(ADDRESS_1);
        let digest: vector<u8> = x"0123456789";
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);

        test.next_tx(ADDRESS_1);
        let proposed_upgrade = quorum_upgrade_policy::create_upgrade(&quorum_upgrade_cap, digest, ctx(&mut test));
        quorum_upgrade_policy::share_upgrade_object(proposed_upgrade);

        test.next_tx(ADDRESS_1);
        let mut quorum_upgrade_cap1 = get_quorum_upgrade_cap(6, 10, &mut test);
        let mut proposal = test.take_shared<ProposedUpgrade>();
        let ticket = quorum_upgrade_policy::authorize_upgrade(
            &mut quorum_upgrade_cap1, 
            &mut proposal, 
            ctx(&mut test),
        );
        let receipt = package::test_upgrade(ticket);
        quorum_upgrade_policy::commit_upgrade(&mut quorum_upgrade_cap, receipt);
        test::return_shared(proposal);

        test.next_tx(ADDRESS_1);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap1);

        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ENotEnoughVotes)]
    fun quorum_upgrade_authorize_upgrade_v2_not_enough_votes() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ENotEnoughVotes)]
    fun quorum_upgrade_authorize_upgrade_v2_not_enough_votes_1() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ENotEnoughVotes)]
    fun quorum_upgrade_authorize_upgrade_v2_not_enough_votes_2() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(2, 2, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ENotEnoughVotes)]
    fun quorum_upgrade_authorize_upgrade_v2_not_enough_votes_3() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(6, 10, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x105, &mut test);
        vote(@0x106, &mut test);
        vote(@0x102, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ESignerMismatch)]
    fun quorum_upgrade_authorize_upgrade_v2_bad_signer() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        let mut quorum_upgrade_cap_1 = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_2, &quorum_upgrade_cap_1, digest, &mut test);

        vote(@0x100, &mut test);
        vote(@0x103, &mut test);
        vote(@0x101, &mut test);
        vote(@0x102, &mut test);

        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap_1, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap_1);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EInvalidProposalForUpgrade)]
    fun quorum_upgrade_authorize_upgrade_v2_bad_voter_cap() {
        let digest: vector<u8> = x"0123456789";
        let digest1: vector<u8> = x"9876543210";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        let quorum_upgrade_cap_1 = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_2, &quorum_upgrade_cap_1, digest1, &mut test);

        vote(@0x102, &mut test);
        vote(@0x103, &mut test);
        vote(@0x101, &mut test);

        perform_upgrade(ADDRESS_2, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap_1);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAlreadyIssued)]
    fun quorum_upgrade_authorize_upgrade_v2_already_issued() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);

        vote(@0x100, &mut test);
        vote(@0x103, &mut test);
        vote(@0x104, &mut test);

        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAlreadyIssued)]
    fun quorum_upgrade_vote_v2_already_issued() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);

        vote(@0x100, &mut test);
        vote(@0x103, &mut test);
        vote(@0x104, &mut test);

        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        vote(@0x101, &mut test);
        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EInvalidVoterForUpgrade)]
    fun quorum_upgrade_v2_bad_voter() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        test.next_tx(@0x100);
        // get the voter cap and use it over the next upgrade and proposal
        let mut voter_cap = test::take_from_address<VotingCap>(&test, @0x100);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        test.next_tx(@0x100);
        let mut proposal = test.take_shared<ProposedUpgrade>();
        quorum_upgrade_policy::vote(&mut proposal, &mut voter_cap, ctx(&mut test));
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test::return_shared(proposal);
        test::return_to_address(@0x100, voter_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAlreadyVoted)]
    fun quorum_upgrade_v2_vote_twice() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);

        vote(@0x100, &mut test);
        vote(@0x100, &mut test);

        end_partial_test(quorum_upgrade_cap, test);
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EAlreadyIssued)]
    fun quorum_upgrade_v2_upgrade_already_issued() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        vote(@0x102, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EInvalidProposerForMetadata)]
    fun quorum_upgrade_v2_invalid_proposer_metadata_change() {
        let digest: vector<u8> = x"0123456789";
        let mut update_metadata_map = vec_map::empty<string::String, string::String>();
        vec_map::insert(&mut update_metadata_map, string::utf8(b"metadata_key"), string::utf8(b"metadata_info"));

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        test.next_tx(ADDRESS_1);
        let mut proposed_upgrade = quorum_upgrade_policy::create_upgrade(&quorum_upgrade_cap, digest, ctx(&mut test));
        test.next_tx(ADDRESS_2);
        quorum_upgrade_policy::add_metadata(&mut proposed_upgrade, update_metadata_map, ctx(&mut test));
        quorum_upgrade_policy::share_upgrade_object(proposed_upgrade);

        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun quorum_upgrade_v2_add_metadata() {
        let digest: vector<u8> = x"0123456789";
        let mut metadata_map = vec_map::empty<string::String, string::String>();
        vec_map::insert(&mut metadata_map, string::utf8(b"metadata_key"), string::utf8(b"metadata_info"));
        vec_map::insert(&mut metadata_map, string::utf8(b"metadata_key_2"), string::utf8(b"metadata_info_2"));

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        test.next_tx(ADDRESS_1);
        let mut proposed_upgrade = quorum_upgrade_policy::create_upgrade(&quorum_upgrade_cap, digest, ctx(&mut test));
        quorum_upgrade_policy::add_metadata(&mut proposed_upgrade, metadata_map, ctx(&mut test));
        quorum_upgrade_policy::share_upgrade_object(proposed_upgrade);

        test.next_tx(@0x100);
        let mut voter_cap = test::take_from_address<VotingCap>(&test, @0x100);
        let mut proposal = test.take_shared<ProposedUpgrade>();
        let metadata_map: VecMap<string::String, string::String> = quorum_upgrade_policy::metadata(&proposal);
        assert!(*vec_map::get(&metadata_map, &string::utf8(b"metadata_key")) == string::utf8(b"metadata_info"), 0);
        assert!(*vec_map::get(&metadata_map, &string::utf8(b"metadata_key_2")) == string::utf8(b"metadata_info_2"), 0);
        quorum_upgrade_policy::vote(&mut proposal, &mut voter_cap, ctx(&mut test));
        test::return_to_address(@0x100, voter_cap);

        test::return_shared(proposal);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::EMetadataAlreadyExists)]
    fun quorum_upgrade_v2_cannot_add_metadata_twice() {
        let digest: vector<u8> = x"0123456789";
        let mut metadata_map = vec_map::empty<string::String, string::String>();
        vec_map::insert(&mut metadata_map, string::utf8(b"metadata_key"), string::utf8(b"metadata_info"));
        vec_map::insert(&mut metadata_map, string::utf8(b"metadata_key_2"), string::utf8(b"metadata_info_2"));
        let update_metadata_map = vec_map::empty<string::String, string::String>();

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        test.next_tx(ADDRESS_1);
        let mut proposed_upgrade = quorum_upgrade_policy::create_upgrade(&quorum_upgrade_cap, digest, ctx(&mut test));
        quorum_upgrade_policy::add_metadata(&mut proposed_upgrade, metadata_map, ctx(&mut test));
        quorum_upgrade_policy::add_metadata(&mut proposed_upgrade, update_metadata_map, ctx(&mut test));
        quorum_upgrade_policy::share_upgrade_object(proposed_upgrade);

        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun quorum_upgrade_v2_no_metadata_perform_upgrade_ok() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_no_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade_and_cleanup(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(ADDRESS_2);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(8, 10, &mut test);
        create_upgrade_no_metadata(ADDRESS_2, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        vote(@0x105, &mut test);
        vote(@0x106, &mut test);
        vote(@0x107, &mut test);
        vote(@0x108, &mut test);
        vote(@0x109, &mut test);
        perform_upgrade_and_cleanup(ADDRESS_2, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x3);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 9, &mut test);
        create_upgrade_no_metadata(@0x3, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        vote(@0x105, &mut test);
        perform_upgrade_and_cleanup(@0x3, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x4);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(1, 100, &mut test);
        create_upgrade_no_metadata(@0x4, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x140, &mut test);
        perform_upgrade_and_cleanup(@0x4, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x5);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_no_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x103, &mut test); 
        vote(@0x100, &mut test); 
        vote(@0x102, &mut test); 
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade_and_cleanup(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun quorum_upgrade_v2_with_metadata_perform_upgrade_ok() {
        let digest: vector<u8> = x"0123456789";

        let mut test = test::begin(ADDRESS_1);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade_and_cleanup(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(ADDRESS_2);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(8, 10, &mut test);
        create_upgrade_with_metadata(ADDRESS_2, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        vote(@0x105, &mut test);
        vote(@0x106, &mut test);
        vote(@0x107, &mut test);
        vote(@0x108, &mut test);
        vote(@0x109, &mut test);
        perform_upgrade_and_cleanup(ADDRESS_2, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x3);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 9, &mut test);
        create_upgrade_with_metadata(@0x3, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x100, &mut test);
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        vote(@0x105, &mut test);
        perform_upgrade_and_cleanup(@0x3, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x4);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(1, 100, &mut test);
        create_upgrade_with_metadata(@0x4, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x140, &mut test);
        perform_upgrade_and_cleanup(@0x4, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();

        let mut test = test::begin(@0x5);
        let mut quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x103, &mut test); 
        vote(@0x100, &mut test); 
        vote(@0x102, &mut test); 
        vote(@0x101, &mut test);
        vote(@0x104, &mut test);
        perform_upgrade_and_cleanup(ADDRESS_1, &mut quorum_upgrade_cap, &mut test);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun test_destroy_proposed_upgrade_ok() {
        let mut test = test::begin(ADDRESS_1);
        let digest: vector<u8> = x"0123456789";
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);

        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x101, &mut test);

        test.next_tx(ADDRESS_1);
        let proposal = test.take_shared<ProposedUpgrade>();
        quorum_upgrade_policy::destroy_proposed_upgrade(proposal, ctx(&mut test));
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    #[expected_failure(abort_code = ::quorum_upgrade_policy::quorum_upgrade_policy::ESignerMismatch)]
    fun test_destroy_proposed_upgrade_wrong_signer() {
        let mut test = test::begin(ADDRESS_1);
        let digest: vector<u8> = x"0123456789";
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);

        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);
        vote(@0x101, &mut test);

        test.next_tx(ADDRESS_2);
        let proposal = test.take_shared<ProposedUpgrade>();
        quorum_upgrade_policy::destroy_proposed_upgrade(proposal, ctx(&mut test));
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }

    #[test]
    fun test_accessor_functions() {
        let mut test = test::begin(ADDRESS_1);
        let digest: vector<u8> = x"0123456789";
        let quorum_upgrade_cap = get_quorum_upgrade_cap(3, 5, &mut test);
        test.next_tx(ADDRESS_1);

        create_upgrade_with_metadata(ADDRESS_1, &quorum_upgrade_cap, digest, &mut test);

        test.next_tx(ADDRESS_1);
        let proposed_upgrade = test.take_shared<ProposedUpgrade>();
        let votes = quorum_upgrade_policy::required_votes(&quorum_upgrade_cap);
        assert!(votes == 3, 0);
        let voters = quorum_upgrade_policy::voters(&quorum_upgrade_cap);
        assert!(voters.size() == 5, 1);
        let proposer = quorum_upgrade_policy::proposer(&proposed_upgrade);
        assert!(proposer == ADDRESS_1, 2);
        let proposal_digest = quorum_upgrade_policy::digest(&proposed_upgrade);
        assert!(proposal_digest == &digest, 3);
        let current_voters = quorum_upgrade_policy::current_voters(&proposed_upgrade);
        assert!(current_voters.is_empty(), 4);
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test::return_shared(proposed_upgrade);
        test.end();
    }

    fun get_quorum_upgrade_cap(
        required_vote: u64, 
        voter_count: u256,
        test: &mut Scenario,
    ): QuorumUpgradeCap {
        let cap = package::test_publish(id(@0x42), ctx(test));
        let voters = get_voters(voter_count, 0x100);
        quorum_upgrade_policy::new(cap, required_vote, voters, ctx(test))
    }

    fun get_voters(count: u256, mut voter: u256): VecSet<address> {
        let mut voters = vec_set::empty();
        while (voter < 0x100u256 + count) {
            vec_set::insert(&mut voters, from_u256(voter));
            voter = voter + 1;
        };
        voters
    }

    fun vote(voter: address, test: &mut Scenario) {
        test::next_tx(test, voter);
        let mut voter_cap = test.take_from_address<VotingCap>(voter);
        let mut proposal = test.take_shared<ProposedUpgrade>();
        quorum_upgrade_policy::vote(&mut proposal, &mut voter_cap, ctx(test));
        test::return_to_address(voter, voter_cap);
        test::return_shared(proposal);
    }

    fun propose_upgrade(
        sender: address, 
        quorum_upgrade_cap: &QuorumUpgradeCap, 
        digest: vector<u8>,
        test: &mut Scenario,
    ) {
        test::next_tx(test, sender);
        quorum_upgrade_policy::propose_upgrade(quorum_upgrade_cap, digest, ctx(test));
    }

    fun create_upgrade_no_metadata(
        sender: address, 
        quorum_upgrade_cap: &QuorumUpgradeCap, 
        digest: vector<u8>,
        test: &mut Scenario,
    ) {
        test::next_tx(test, sender);
        let proposed_upgrade = quorum_upgrade_policy::create_upgrade(quorum_upgrade_cap, digest, ctx(test));
        quorum_upgrade_policy::share_upgrade_object(proposed_upgrade);
    }

    fun create_upgrade_with_metadata(
        sender: address, 
        quorum_upgrade_cap: &QuorumUpgradeCap, 
        digest: vector<u8>,
        test: &mut Scenario,
    ) {
        test::next_tx(test, sender);
        let mut metadata_map = vec_map::empty<string::String, string::String>();
        vec_map::insert(&mut metadata_map, string::utf8(b"metadata_key"), string::utf8(b"metadata_info"));
        let mut proposed_upgrade = quorum_upgrade_policy::create_upgrade(quorum_upgrade_cap, digest, ctx(test));
        quorum_upgrade_policy::add_metadata(&mut proposed_upgrade, metadata_map, ctx(test));
        quorum_upgrade_policy::share_upgrade_object(proposed_upgrade);
    }

    fun perform_upgrade(
        sender: address, 
        quorum_upgrade_cap: &mut QuorumUpgradeCap, 
        test: &mut Scenario,
    ) {
        test::next_tx(test, sender);
        let mut proposal = test.take_shared<ProposedUpgrade>();
        let ticket = quorum_upgrade_policy::authorize_upgrade(
            quorum_upgrade_cap, 
            &mut proposal, 
            ctx(test),
        );
        let receipt = package::test_upgrade(ticket);
        quorum_upgrade_policy::commit_upgrade(quorum_upgrade_cap, receipt);
        test::return_shared(proposal);
    }

    fun perform_upgrade_and_cleanup(
        sender: address, 
        quorum_upgrade_cap: &mut QuorumUpgradeCap, 
        test: &mut Scenario,
    ) {
        test::next_tx(test, sender);
        let proposal = test.take_shared<ProposedUpgrade>();
        let ticket = quorum_upgrade_policy::authorize_upgrade_and_cleanup(
            quorum_upgrade_cap, 
            proposal,
            ctx(test),
        );
        let receipt = package::test_upgrade(ticket);
        quorum_upgrade_policy::commit_upgrade(quorum_upgrade_cap, receipt);
    }

    fun end_partial_test(quorum_upgrade_cap: QuorumUpgradeCap, mut test: Scenario) {
        test.next_tx(ADDRESS_1);
        let proposal = test.take_shared<ProposedUpgrade>();
        quorum_upgrade_policy::destroy_proposed_upgrade(proposal, ctx(&mut test));
        quorum_upgrade_policy::make_immutable(quorum_upgrade_cap);
        test.end();
    }
}

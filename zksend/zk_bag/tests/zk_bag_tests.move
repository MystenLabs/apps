// Copyright (c), Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module zk_bag::zk_bag_tests {

    use std::vector;

    use sui::tx_context::TxContext;
    use sui::object::{UID, Self};

    use sui::test_scenario::{Self as ts, ctx, Scenario};

    use zk_bag::zk_bag::{Self, BagStore};

    struct TestItem has key, store {
        id: UID
    }

    const USER_ONE: address = @0x1;
    const USER_TWO: address = @0x2;
    const USER_THREE: address = @0x3;

    // TODO: Fix this when Receiving tests are out.
    // #[test]
    // fun flow() {
    //     let scenario_val = ts::begin(USER_ONE);
    //     let scenario = &mut scenario_val;

    //     init_tests(scenario);
    //     let item_ids = new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);

    //     // RECEIVER PART
    //     ts::next_tx(scenario, USER_TWO);

    //     let store = ts::take_shared<BagStore>(scenario);

    //     let (bag, claim_proof) = zk_bag::init_claim(&mut store, ctx(scenario));

    //     while(vector::length(&item_ids) > 0) {
    //         let id = vector::pop_back(&mut item_ids);
    //         let item: TestItem = zk_bag::claim(&mut bag, &claim_proof, id);
    //         sui::transfer::transfer(item, USER_TWO);
    //     };

    //     zk_bag::finalize(bag, claim_proof);

    //     ts::return_shared(store);

    //     ts::end(scenario_val);
    // }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::ETooManyItems)]
    fun too_many_items(){
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        new_bag_with_items(scenario, 51, USER_ONE, USER_TWO);

        abort 1337
    }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::EUnauthorized)]
    fun unauthorized_access(){
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
        
        ts::next_tx(scenario, USER_THREE);
        let store = ts::take_shared<BagStore>(scenario);
        let (_bag, _claim) = zk_bag::reclaim(&mut store, USER_TWO, ctx(scenario));

        abort 1337
    }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::EClaimAddressNotExists)]
    fun tries_to_claim_non_existing_bag() {
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        ts::next_tx(scenario, USER_THREE);
        let store = ts::take_shared<BagStore>(scenario);
        let (_bag, _claim) = zk_bag::init_claim(&mut store, ctx(scenario));

        abort 1337
    }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::EClaimAddressAlreadyExists)]
    fun bag_already_exists() {
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
        new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);

        abort 1337
    }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::EBagNotEmpty)]
    fun try_to_finalize_non_empty_bag(){
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
        
        ts::next_tx(scenario, USER_TWO);
        let store = ts::take_shared<BagStore>(scenario);
        let (bag, claim_proof) = zk_bag::init_claim(&mut store, ctx(scenario));
        zk_bag::finalize(bag, claim_proof);

        abort 1337
    }

    // #[test, expected_failure(abort_code= zk_bag::zk_bag::EItemNotExists)]
    // fun tries_to_claim_non_existing_id(){
    //     let scenario_val = ts::begin(USER_ONE);
    //     let scenario = &mut scenario_val;

    //     init_tests(scenario);
    //     new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
        
    //     ts::next_tx(scenario, USER_TWO);
    //     let store = ts::take_shared<BagStore>(scenario);
    //     let (bag, claim_proof) = zk_bag::init_claim(&mut store, USER_TWO, ctx(scenario));

    //     // tries to claim using an id that does not exist on the object.
    //     let _item: TestItem = zk_bag::claim(&mut bag, &claim_proof, 2);

    //     abort 1337
    // }

    // #[test, expected_failure(abort_code= zk_bag::zk_bag::EUnauthorizedProof)]
    // fun try_to_claim_with_invalid_proof(){
    //     let scenario_val = ts::begin(USER_ONE);
    //     let scenario = &mut scenario_val;

    //     init_tests(scenario);
    //     new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
    //     new_bag_with_items(scenario, 2, USER_ONE, USER_THREE);
        
    //     ts::next_tx(scenario, USER_ONE);
    //     let store = ts::take_shared<BagStore>(scenario);
    //     let (bag, _claim_proof) = zk_bag::init_claim(&mut store, USER_TWO, ctx(scenario));
    //     let (_bag_two, claim_proof_two) = zk_bag::init_claim(&mut store, USER_THREE, ctx(scenario));

    //     let _item: TestItem = zk_bag::claim(&mut bag, &claim_proof_two, 0);

    //     abort 1337
    // }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::EUnauthorizedProof)]
    fun try_to_finalize_with_invalid_proof(){
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
        new_bag_with_items(scenario, 2, USER_ONE, USER_THREE);
        
        ts::next_tx(scenario, USER_TWO);
        let store = ts::take_shared<BagStore>(scenario);

        let (bag, _claim_proof) = zk_bag::init_claim(&mut store, ctx(scenario));

        ts::next_tx(scenario, USER_THREE);
        let (_bag_two, claim_proof_two) = zk_bag::init_claim(&mut store, ctx(scenario));

        zk_bag::finalize(bag, claim_proof_two);

        abort 1337
    }

   #[test]
    fun switch_receiver_successfully() {
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        new_bag_with_items(scenario, 1, USER_ONE, USER_TWO);
        
        ts::next_tx(scenario, USER_ONE);
        let store = ts::take_shared<BagStore>(scenario);
        zk_bag::update_receiver(&mut store, USER_TWO, USER_THREE, ctx(scenario));

        ts::return_shared(store);
        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::EUnauthorized)]
    fun non_owner_tries_to_switch_recipient() {
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        new_bag_with_items(scenario, 1, USER_ONE, USER_TWO);
        
        ts::next_tx(scenario, USER_TWO);
        let store = ts::take_shared<BagStore>(scenario);
        zk_bag::update_receiver(&mut store, USER_TWO, USER_THREE, ctx(scenario));

        ts::return_shared(store);
        ts::end(scenario_val);
    }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::EClaimAddressNotExists)]
    fun tries_to_switch_non_existing_address() {
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);

        ts::next_tx(scenario, USER_TWO);
        let store = ts::take_shared<BagStore>(scenario);
        zk_bag::update_receiver(&mut store, USER_THREE, USER_TWO, ctx(scenario));

        abort 1337
    }

    #[test, expected_failure(abort_code= zk_bag::zk_bag::EClaimAddressAlreadyExists)]
    fun tries_to_switch_to_address_that_already_has_bag() {
        let scenario_val = ts::begin(USER_ONE);
        let scenario = &mut scenario_val;

        init_tests(scenario);
        new_bag_with_items(scenario, 1, USER_ONE, USER_TWO);
        new_bag_with_items(scenario, 1, USER_ONE, USER_THREE);

        ts::next_tx(scenario, USER_TWO);
        let store = ts::take_shared<BagStore>(scenario);
        zk_bag::update_receiver(&mut store, USER_TWO, USER_THREE, ctx(scenario));

        abort 1337
    }


    fun init_tests(scenario: &mut Scenario) {
        ts::next_tx(scenario, USER_ONE);
        zk_bag::init_for_testing(ctx(scenario))
    }

    fun new_bag_with_items(scenario: &mut Scenario, item_count: u8, sender: address, recipient: address): vector<address> {
        ts::next_tx(scenario, sender);
        let store = ts::take_shared<BagStore>(scenario);

        let addresses: vector<address> = vector::empty();

        zk_bag::new(&mut store, recipient, ctx(scenario));

        let i: u8 = 0;
        while(i < item_count){
            let item = new_item(ctx(scenario));
            vector::push_back(&mut addresses, object::id_address(&item));
            zk_bag::add(&mut store, recipient, item, ctx(scenario));
            i = i + 1;
        };

        ts::return_shared(store);

        addresses
    }

    fun new_item(ctx: &mut TxContext): TestItem {
        TestItem {
            id: object::new(ctx)
        }
    }

}

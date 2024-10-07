// Copyright (c), Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module zk_bag::zk_bag_tests;

use sui::test_scenario::{Self as ts, Scenario};
use zk_bag::zk_bag::{Self, BagStore};

public struct TestItem has key, store {
    id: UID,
}

const USER_ONE: address = @0x1;
const USER_TWO: address = @0x2;
const USER_THREE: address = @0x3;

// TODO: Fix this when Receiving tests are out.
#[test]
fun flow() {
    let mut scenario = ts::begin(USER_ONE);

    init_tests(&mut scenario);
    let mut item_ids = new_bag_with_items(&mut scenario, 2, USER_ONE, USER_TWO);

    // RECEIVER PART
    scenario.next_tx(USER_TWO);

    let mut store = scenario.take_shared<BagStore>();

    let (mut bag, claim_proof) = store.init_claim(scenario.ctx());

    while (item_ids.length() > 0) {
        let item: TestItem = bag.claim(
            &claim_proof,
            ts::receiving_ticket_by_id(item_ids.pop_back()),
        );
        sui::transfer::transfer(item, USER_TWO);
    };

    bag.finalize(claim_proof);

    ts::return_shared(store);

    scenario.end();
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::ETooManyItems)]
fun too_many_items() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    new_bag_with_items(scenario, 51, USER_ONE, USER_TWO);

    abort 1337
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::EUnauthorized)]
fun unauthorized_access() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);

    scenario.next_tx(USER_THREE);
    let mut store = scenario.take_shared<BagStore>();
    let (_bag, _claim) = store.reclaim(USER_TWO, scenario.ctx());

    abort 1337
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::EClaimAddressNotExists)]
fun tries_to_claim_non_existing_bag() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    scenario.next_tx(USER_THREE);
    let mut store = scenario.take_shared<BagStore>();
    let (_bag, _claim) = store.init_claim(scenario.ctx());

    abort 1337
}

#[
    test,
    expected_failure(
        abort_code = ::zk_bag::zk_bag::EClaimAddressAlreadyExists,
    ),
]
fun bag_already_exists() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
    new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);

    abort 1337
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::EBagNotEmpty)]
fun try_to_finalize_non_empty_bag() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);

    scenario.next_tx(USER_TWO);
    let mut store = scenario.take_shared<BagStore>();
    let (bag, claim_proof) = store.init_claim(scenario.ctx());
    bag.finalize(claim_proof);

    abort 1337
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::EItemNotExists)]
fun tries_to_claim_non_existing_id() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    let _ = new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);

    let random_item = TestItem {
        id: object::new(scenario.ctx()),
    };

    let random_item_id = object::id(&random_item);

    scenario.next_tx(USER_TWO);
    let mut store = scenario.take_shared<BagStore>();

    let (mut bag, claim_proof) = store.init_claim(scenario.ctx());
    sui::transfer::public_transfer(random_item, object::id_address(&bag));

    scenario.next_tx(USER_TWO);

    // tries to claim using an id that does not exist on the object.
    let _item: TestItem = bag.claim(
        &claim_proof,
        ts::receiving_ticket_by_id(random_item_id),
    );

    abort 1337
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::EUnauthorizedProof)]
fun try_to_claim_with_invalid_proof() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    let mut item_ids = new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
    new_bag_with_items(scenario, 2, USER_ONE, USER_THREE);

    scenario.next_tx(USER_ONE);
    let mut store = scenario.take_shared<BagStore>();
    let (mut bag, _claim_proof) = store.reclaim(USER_TWO, scenario.ctx());
    let (_bag_two, claim_proof_two) = store.reclaim(USER_THREE, scenario.ctx());

    let _item: TestItem = bag.claim(
        &claim_proof_two,
        ts::receiving_ticket_by_id(vector::pop_back(&mut item_ids)),
    );

    abort 1337
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::EUnauthorizedProof)]
fun try_to_finalize_with_invalid_proof() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    new_bag_with_items(scenario, 2, USER_ONE, USER_TWO);
    new_bag_with_items(scenario, 2, USER_ONE, USER_THREE);

    scenario.next_tx(USER_TWO);
    let mut store = scenario.take_shared<BagStore>();

    let (bag, _claim_proof) = store.init_claim(scenario.ctx());

    scenario.next_tx(USER_THREE);
    let (_bag_two, claim_proof_two) = store.init_claim(scenario.ctx());

    bag.finalize(claim_proof_two);

    abort 1337
}

#[test]
fun switch_receiver_successfully() {
    let mut scenario = ts::begin(USER_ONE);

    init_tests(&mut scenario);
    new_bag_with_items(&mut scenario, 1, USER_ONE, USER_TWO);

    scenario.next_tx(USER_ONE);
    let mut store = scenario.take_shared<BagStore>();
    store.update_receiver(USER_TWO, USER_THREE, scenario.ctx());

    ts::return_shared(store);
    scenario.end();
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::EUnauthorized)]
fun non_owner_tries_to_switch_recipient() {
    let mut scenario = ts::begin(USER_ONE);

    init_tests(&mut scenario);
    new_bag_with_items(&mut scenario, 1, USER_ONE, USER_TWO);

    scenario.next_tx(USER_TWO);
    let mut store = scenario.take_shared<BagStore>();
    store.update_receiver(USER_TWO, USER_THREE, scenario.ctx());

    ts::return_shared(store);
    scenario.end();
}

#[test, expected_failure(abort_code = ::zk_bag::zk_bag::EClaimAddressNotExists)]
fun tries_to_switch_non_existing_address() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);

    scenario.next_tx(USER_TWO);
    let mut store = scenario.take_shared<BagStore>();
    store.update_receiver(USER_THREE, USER_TWO, scenario.ctx());

    abort 1337
}

#[
    test,
    expected_failure(
        abort_code = ::zk_bag::zk_bag::EClaimAddressAlreadyExists,
    ),
]
fun tries_to_switch_to_address_that_already_has_bag() {
    let mut scenario_val = ts::begin(USER_ONE);
    let scenario = &mut scenario_val;

    init_tests(scenario);
    new_bag_with_items(scenario, 1, USER_ONE, USER_TWO);
    new_bag_with_items(scenario, 1, USER_ONE, USER_THREE);

    scenario.next_tx(USER_TWO);
    let mut store = scenario.take_shared<BagStore>();
    store.update_receiver(USER_TWO, USER_THREE, scenario.ctx());

    abort 1337
}

fun init_tests(scenario: &mut Scenario) {
    scenario.next_tx(USER_ONE);
    zk_bag::init_for_testing(scenario.ctx())
}

fun new_bag_with_items(
    scenario: &mut Scenario,
    item_count: u8,
    sender: address,
    recipient: address,
): vector<ID> {
    scenario.next_tx(sender);
    let mut store = scenario.take_shared<BagStore>();

    let mut addresses: vector<ID> = vector[];

    store.new(recipient, scenario.ctx());

    let mut i: u8 = 0;
    while (i < item_count) {
        let item = new_item(scenario.ctx());
        addresses.push_back(object::id(&item));
        store.add(recipient, item, scenario.ctx());
        i = i + 1;
    };

    ts::return_shared(store);

    addresses
}

fun new_item(ctx: &mut TxContext): TestItem {
    TestItem {
        id: object::new(ctx),
    }
}

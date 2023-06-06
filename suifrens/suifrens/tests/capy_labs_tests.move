// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
// TODO: finish prepping the unit testing framework
module suifrens::capy_labs_unit_tests {
    use std::vector;
    use std::string::utf8;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, dummy};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use suifrens::suifrens::{Self as sf, AdminCap, SuiFren as SF};
    use suifrens::capy_labs::{Self as labs, CapyLabsApp};
    use suifrens::capy::Capy;

    const DEFAULT_ABORT: u64 = 1337;

    #[test]
    #[expected_failure(abort_code = DEFAULT_ABORT)]
    fun default_mix() {
        let ctx = sui::tx_context::dummy();
        let clock = clock();
        let (p1, p2) = get_parents<Capy>(&mut ctx);
        let app = authorized_app(&mut ctx);

        skip_epochs(&mut ctx, 1);

        let _kid = {
            let coin = mint();
            let capy = labs::mix(&mut app, &mut p1, &mut p2, &clock, &mut coin, &mut ctx);
            coin::destroy_zero(coin);
            capy
        };

        abort 1337
    }


    // === Setup and wrapup ===

    fun get_parents<T>(ctx: &mut TxContext): (SF<T>, SF<T>) {
        (sf::mint_for_testing(ctx), sf::mint_for_testing(ctx))
    }

    fun burn_family<T>(family: vector<SF<T>>) {
        while (vector::length(&family) > 0) {
            sf::burn_for_testing(vector::pop_back(&mut family));
        };
        vector::destroy_empty(family);
    }

    fun skip_epochs(ctx: &mut TxContext, num: u8) {
        while (num > 0) {
            tx_context::increment_epoch_number(ctx);
            num = num - 1;
        };
    }

    /// Get already authorized application!
    fun authorized_app(ctx: &mut TxContext): CapyLabsApp {
        let app = labs::create_app(ctx);
        let cap = cap();
        labs::add_genes<Capy>(&cap, &mut app, x"00");
        labs::set_mixing_price(&cap, &mut app, 100000);
        labs::authorize<Capy>(
            &cap, &mut app,
            0, utf8(b"test_beasts"),
            1000000,
            1000,
            vector[utf8(b"yayaya")]
        );
        return_cap(cap);
        app
    }

    fun mint(): Coin<SUI> { coin::mint_for_testing(100000, &mut ctx()) }
    fun cap(): AdminCap { sf::test_new_admin_cap(&mut ctx()) }
    fun app(): UID { object::new(&mut dummy()) }
    fun clock(): Clock { clock::create_for_testing(&mut dummy()) }
    fun ctx(): TxContext { dummy() }

    fun return_sf<T>(sf: SF<T>) { sf::burn_for_testing(sf) }
    fun return_cap(cap: AdminCap) { sf::test_destroy_admin_cap(cap) }
    fun return_clock(clock: Clock) { clock::destroy_for_testing(clock) }
    fun return_app(uid: UID) { object::delete(uid) }
}

#[test_only]
/// Tests the authorization flow based on the `core_example`.
module suifrens::capy_labs_tests {
    use std::vector as vec;
    use sui::test_scenario as ts;

    use suifrens::suifrens as sf;
    use suifrens::capy_labs as labs;

    #[test]
    fun test_change_domain_range_in_numbers(){
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);
        let seed = labs::get_seed_for_test(ts::ctx(&mut test));
        let common : vector<u8> = labs::derive(&seed, 2);

        let (i, len) = (0u64, vec::length(&common));

        while (i < len) {
            let num : u8 = *vec::borrow(&common, i);
            let restricted_num : u16 = (num as u16) * 70u16 /100u16;
            let new_num = (restricted_num as u8);
            assert!(new_num <= 178, 666);
            i = i+1;
        };
        ts::end(test);
    }

    #[test]
    fun test_cooldown_period() {
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let labs_app = labs::create_app(ts::ctx(&mut test));

        let default_cooldown_period = labs::get_cooldown_period(&mut labs_app);
        assert!(default_cooldown_period == 1, 0);

        labs::set_cooldown_period(&admin_cap, &mut labs_app, 2);

        let cooldown_period2 = labs::get_cooldown_period(&mut labs_app);
        assert!(cooldown_period2 == 2, 0);

        sf::test_destroy_admin_cap(admin_cap);
        labs::close_app(labs_app);
        ts::end(test);
    }

    #[test]
    fun test_mixing_price() {
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);


        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let labs_app = labs::create_app(ts::ctx(&mut test));

        let default_price = labs::get_mixing_price(&labs_app);
        assert!(default_price == 10_000_000_000, 0);

        let new_mixing_price = 1234567890000000000;
        labs::set_mixing_price(&admin_cap, &mut labs_app, new_mixing_price);

        let price = labs::get_mixing_price(&mut labs_app);
        assert!(price == new_mixing_price, 0);

        sf::test_destroy_admin_cap(admin_cap);
        labs::close_app(labs_app);
        ts::end(test);
    }

    #[test]
    fun test_mixing_limit() {
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);

        let default_mix_limit = 5;

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let labs_app = labs::create_app(ts::ctx(&mut test));

        let default_price = labs::get_mixing_limit(&labs_app);
        assert!(default_price == default_mix_limit, 0);

        let new_mixing_limit = 55;
        labs::set_mixing_limit(&admin_cap, &mut labs_app, new_mixing_limit);

        let limit = labs::get_mixing_limit(&mut labs_app);
        assert!(limit == new_mixing_limit, 0);

        sf::test_destroy_admin_cap(admin_cap);
        labs::close_app(labs_app);
        ts::end(test);
    }
}

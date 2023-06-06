// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module accessories::accessories_tests {
    use std::string::utf8;
    use std::vector;
    use std::option;

    use sui::coin;
    use sui::sui::SUI;
    use sui::tx_context;
    use sui::test_scenario as ts;

    use accessories::store as accs;
    use accessories::accessories as acc;
    use suifrens::capy::Capy;
    use suifrens::suifrens as sf;
    use suifrens::genesis as genesis;

    const DEFAULT_MINT_PRICE :u64 = 8_000_000_000;

    #[test]
    fun test_buy_accessory() {
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);

        // Create Accs Store Owner Cap
        // Create Accessories application
        let accs_store_owner_cap = accs::test_accs_store_owner_cap(ts::ctx(&mut test));
        let accessories_app = accs::create_app(ts::ctx(&mut test));
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));

        // Authorize the app to mint and burn the adminCap
        accs::authorize(&admin_cap, &mut accessories_app);
        sf::test_destroy_admin_cap(admin_cap);

        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro hat"), utf8(b"head"), 10000000, option::none(), ts::ctx(&mut test));
        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro suit"), utf8(b"body"), 10000000, option::none(), ts::ctx(&mut test));
        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro boots"), utf8(b"legs"), 500000, option::none(), ts::ctx(&mut test));

        let coin = coin::mint_for_testing<SUI>(10000000, ts::ctx(&mut test));
        let astro_hat = accs::buy(&mut accessories_app, utf8(b"astro hat"), &mut coin, ts::ctx(&mut test));

        assert!(acc::name(&astro_hat) == utf8(b"astro hat"), 0);
        assert!(acc::type(&astro_hat) == utf8(b"head"), 0);

        acc::test_burn(astro_hat);
        accs::test_destroy_accs_store_owner_cap(accs_store_owner_cap);
        accs::close_app(accessories_app);
        coin::burn_for_testing<SUI>(coin);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = accessories::accessories::ENotAuthorized)]
    fun test_buy_accessory_fail_not_authorized() {
        let ctx = tx_context::dummy();
        let store = accs::create_app(&mut ctx);
        let owner_cap = accs::test_accs_store_owner_cap(&mut ctx);

        accs::add_listing(&owner_cap, &mut store, utf8(b"astro hat"), utf8(b"head"), 10000000, option::none(), &mut ctx);
        let payment = coin::mint_for_testing<SUI>(10000000, &mut ctx);
        let _acc = accs::buy(&mut store, utf8(b"astro hat"), &mut payment, &mut ctx);

        abort 1337
    }

    #[test]
    #[expected_failure(abort_code = accessories::accessories::ENotAuthorized)]
    fun test_buy_accessory_fail_deauthorized() {
        let ctx = tx_context::dummy();
        let store = accs::create_app(&mut ctx);
        let owner_cap = accs::test_accs_store_owner_cap(&mut ctx);
        let admin_cap = sf::test_new_admin_cap(&mut ctx);

        accs::authorize(&admin_cap, &mut store);
        accs::deauthorize(&admin_cap, &mut store);

        accs::add_listing(&owner_cap, &mut store, utf8(b"astro hat"), utf8(b"head"), 10000000, option::none(), &mut ctx);
        let payment = coin::mint_for_testing<SUI>(10000000, &mut ctx);
        let _acc = accs::buy(&mut store, utf8(b"astro hat"), &mut payment, &mut ctx);

        abort 1337
    }


    #[test]
    #[expected_failure(abort_code = accessories::store::EAmountIncorrect)]
    fun test_buy_accessory_incorrect_amount() {
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);

        // Create Accs Store Owner Cap
        // Create Accessories application
        let accs_store_owner_cap = accs::test_accs_store_owner_cap(ts::ctx(&mut test));
        let accessories_app = accs::create_app(ts::ctx(&mut test));
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));

        // Authorize the app to mint and burn the adminCap
        accs::authorize(&admin_cap, &mut accessories_app);
        sf::test_destroy_admin_cap(admin_cap);

        // List an accessory for 2 SUI
        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro hat"), utf8(b"head"), 2, option::none(), ts::ctx(&mut test));

        // Provide 1 SUI
        let coin = coin::mint_for_testing<SUI>(1, ts::ctx(&mut test));
        let astro_hat = accs::buy(&mut accessories_app, utf8(b"astro hat"), &mut coin, ts::ctx(&mut test));

        assert!(acc::name(&astro_hat) == utf8(b"astro hat"), 0);
        assert!(acc::type(&astro_hat) == utf8(b"head"), 0);

        acc::test_burn(astro_hat);
        accs::test_destroy_accs_store_owner_cap(accs_store_owner_cap);
        accs::close_app(accessories_app);
        coin::burn_for_testing<SUI>(coin);
        ts::end(test);
    }

    #[test]
    fun test_add() {
        let user = @0x1;
        let test = ts::begin(user);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        ts::next_tx(&mut test, user);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let genesis = genesis::create_app(ts::ctx(&mut test));
        // Attach admin permission
        genesis::authorize<Capy>(&admin_cap, &mut genesis, 11, utf8(b"cohort1"), 10, 10, vector::singleton(utf8(b"US")));
        genesis::add_genes<Capy>(&admin_cap, &mut genesis, x"00");

        // Create Accs Store Owner Cap
        // Create Accessories application
        let accs_store_owner_cap = accs::test_accs_store_owner_cap(ts::ctx(&mut test));
        let accessories_app = accs::create_app(ts::ctx(&mut test));
        // Authorize the app to mint and burn the adminCap
        accs::authorize(&admin_cap, &mut accessories_app);
        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro hat"), utf8(b"head"), 10000000, option::none(), ts::ctx(&mut test));

        let acc_coin = coin::mint_for_testing<SUI>(10000000, ts::ctx(&mut test));
        let astro_hat = accs::buy(&mut accessories_app, utf8(b"astro hat"), &mut acc_coin, ts::ctx(&mut test));

        assert!(acc::name(&astro_hat) == utf8(b"astro hat"), 0);
        assert!(acc::type(&astro_hat) == utf8(b"head"), 0);

        let suifren_coin = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        // Create a SuiFren
        let suifren = genesis::mint(&mut genesis, &clock, &mut suifren_coin, ts::ctx(&mut test));

        acc::add(&mut suifren, astro_hat);

        genesis::destroy_capy(&mut genesis, suifren);
        sf::test_destroy_admin_cap(admin_cap);
        genesis::close_app(genesis);
        accs::test_destroy_accs_store_owner_cap(accs_store_owner_cap);
        accs::close_app(accessories_app);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(suifren_coin);
        coin::burn_for_testing<SUI>(acc_coin);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = accessories::accessories::EAccessoryTypeDoesNotExist)]
    fun test_remove_type_from_suifren_that_doesnt_exist() {
        let user = @0x1;
        let test = ts::begin(user);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        ts::next_tx(&mut test, user);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let genesis = genesis::create_app(ts::ctx(&mut test));
        // Attach admin permission
        genesis::authorize<Capy>(&admin_cap, &mut genesis, 11, utf8(b"cohort1"), 10, 10, vector::singleton(utf8(b"US")));
        genesis::add_genes<Capy>(&admin_cap, &mut genesis, x"00");

        // Create Accs Store Owner Cap
        let accs_store_owner_cap = accs::test_accs_store_owner_cap(ts::ctx(&mut test));

        // Create Accessories application
        let accessories_app = accs::create_app(ts::ctx(&mut test));

        let suifren_coin = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        // Create a SuiFren
        let suifren = genesis::mint(&mut genesis, &clock, &mut suifren_coin, ts::ctx(&mut test));

        let body_acc = acc::remove(&mut suifren, utf8(b"body"));

        acc::test_burn(body_acc);
        genesis::destroy_capy(&mut genesis, suifren);
        sf::test_destroy_admin_cap(admin_cap);
        genesis::close_app(genesis);
        accs::test_destroy_accs_store_owner_cap(accs_store_owner_cap);
        accs::close_app(accessories_app);
        ts::return_shared(clock);
        coin::burn_for_testing<SUI>(suifren_coin);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = accessories::store::ENotAvailableQuantity)]
    fun test_not_available_quantity() {
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);

        // Create Accs Store Owner Cap
        // Create Accessories application
        let accs_store_owner_cap = accs::test_accs_store_owner_cap(ts::ctx(&mut test));
        let accessories_app = accs::create_app(ts::ctx(&mut test));
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));

        // Authorize the app to mint and burn the adminCap
        accs::authorize(&admin_cap, &mut accessories_app);
        sf::test_destroy_admin_cap(admin_cap);

        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro hat"), utf8(b"head"), 10000000, option::some(2), ts::ctx(&mut test));

        let coin_0 = coin::mint_for_testing<SUI>(10000000, ts::ctx(&mut test));
        let astro_hat_0 = accs::buy(&mut accessories_app, utf8(b"astro hat"), &mut coin_0, ts::ctx(&mut test));
        let coin_1 = coin::mint_for_testing<SUI>(10000000, ts::ctx(&mut test));
        let astro_hat_1 = accs::buy(&mut accessories_app, utf8(b"astro hat"), &mut coin_1, ts::ctx(&mut test));
        let coin_2 = coin::mint_for_testing<SUI>(10000000, ts::ctx(&mut test));
        let astro_hat_2 = accs::buy(&mut accessories_app, utf8(b"astro hat"), &mut coin_2, ts::ctx(&mut test));

        acc::test_burn(astro_hat_2);
        acc::test_burn(astro_hat_1);
        acc::test_burn(astro_hat_0);
        accs::test_destroy_accs_store_owner_cap(accs_store_owner_cap);
        accs::close_app(accessories_app);
        coin::burn_for_testing<SUI>(coin_2);
        coin::burn_for_testing<SUI>(coin_1);
        coin::burn_for_testing<SUI>(coin_0);
        ts::end(test);
    }

    #[test]
    fun test_accessory_price() {
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);

        // Create Accs Store Owner Cap
        // Create Accessories application
        let accs_store_owner_cap = accs::test_accs_store_owner_cap(ts::ctx(&mut test));
        let accessories_app = accs::create_app(ts::ctx(&mut test));
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));

        // Authorize the app to mint and burn the adminCap
        accs::authorize(&admin_cap, &mut accessories_app);
        sf::test_destroy_admin_cap(admin_cap);

        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro hat"), utf8(b"head"), 10000000, option::none(), ts::ctx(&mut test));
        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro suit"), utf8(b"body"), 10000000, option::none(), ts::ctx(&mut test));
        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro boots"), utf8(b"legs"), 500000, option::none(), ts::ctx(&mut test));

        assert!(accs::price(&accessories_app, utf8(b"astro hat")) == 10000000, 0);
        assert!(accs::price(&accessories_app, utf8(b"astro suit")) == 10000000, 0);
        assert!(accs::price(&accessories_app, utf8(b"astro boots")) == 500000, 0);
        assert!(accs::price(&accessories_app, utf8(b"astro hat")) == 10000000, 0);

        let coin = coin::mint_for_testing<SUI>(10000000, ts::ctx(&mut test));
        let astro_hat = accs::buy(&mut accessories_app, utf8(b"astro hat"), &mut coin, ts::ctx(&mut test));

        acc::test_burn(astro_hat);
        accs::test_destroy_accs_store_owner_cap(accs_store_owner_cap);
        accs::close_app(accessories_app);
        coin::burn_for_testing<SUI>(coin);
        ts::end(test);
    }

    #[test]
    fun test_accessory_update_price() {
        let user = @0x1;
        let test = ts::begin(user);
        ts::next_tx(&mut test, user);

        // Create Accs Store Owner Cap
        // Create Accessories application
        let accs_store_owner_cap = accs::test_accs_store_owner_cap(ts::ctx(&mut test));
        let accessories_app = accs::create_app(ts::ctx(&mut test));
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));

        // Authorize the app to mint and burn the adminCap
        accs::authorize(&admin_cap, &mut accessories_app);
        sf::test_destroy_admin_cap(admin_cap);

        accs::add_listing(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro hat"), utf8(b"head"), 10000000, option::none(), ts::ctx(&mut test));
        assert!(accs::price(&accessories_app, utf8(b"astro hat")) == 10000000, 0);
        accs::update_price(&accs_store_owner_cap, &mut accessories_app, utf8(b"astro hat"), 10);
        assert!(accs::price(&accessories_app, utf8(b"astro hat")) == 10, 0);

        accs::test_destroy_accs_store_owner_cap(accs_store_owner_cap);
        accs::close_app(accessories_app);
        ts::end(test);
    }

}

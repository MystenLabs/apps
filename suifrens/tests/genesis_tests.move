// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// Tests the authorization flow based on the `core_example`.
module suifrens::genesis_tests {
    use std::string::utf8;
    use std::vector;

    use sui::test_scenario as ts;
    use sui::coin::{Self};
    use sui::sui::SUI;
    use suifrens::capy::Capy;
    use suifrens::suifrens as sf;
    use suifrens::genesis as app;
    use suifrens::capy_labs;
    use sui::tx_context;

    const DEFAULT_MINT_PRICE: u64 = 8_000_000_000;
    const DEFAULT_MINT_PRICE_LOWER: u64 = 10;
    const DEFAULT_MINT_PRICE_HIGHER: u64 = 13_000_000_000;
    const DEFAULT_MIX_PRICE: u64 = 10_000_000_000;

    #[test]
    fun test_basic_mint_flow() {
        let user1 = @0x1;
        let test = ts::begin(user1);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        ts::next_tx(&mut test, user1);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 10, 10, vector::singleton(utf8(b"US")));

        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::close_app(app);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::genesis::EAmountIncorrect)]
    fun test_basic_mint_flow_fail_lower_payment() {
        let user1 = @0x1;
        let test = ts::begin(user1);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        ts::next_tx(&mut test, user1);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 10, 10, vector::singleton(utf8(b"US")));

        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay_lower = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE_LOWER, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay_lower, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::close_app(app);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay_lower);
        ts::end(test);
    }

    #[test]
    fun test_basic_mint_flow_higher_payment() {
        let user1 = @0x1;
        let test = ts::begin(user1);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        ts::next_tx(&mut test, user1);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 10, 10, vector::singleton(utf8(b"US")));

        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay_higher = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE_HIGHER, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay_higher, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::close_app(app);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay_higher);
        ts::end(test);
    }

    #[test]
    fun test_capy_mix() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        tx_context::increment_epoch_number(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        // Add necessary Genes
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        let coin_to_pay2 = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        let _capy2 = app::mint(&mut app, &clock, &mut coin_to_pay2, ts::ctx(&mut test));

        let capy_labs = capy_labs::create_app(ts::ctx(&mut test));
        capy_labs::authorize<Capy>(&admin_cap, &mut capy_labs, 11,utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));

        capy_labs::add_genes<Capy>(&admin_cap,&mut capy_labs,  x"00");

        let coin_to_pay_mix = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));

        let _mixedCapy = capy_labs::mix(&mut capy_labs, &mut  _capy, &mut  _capy2, &clock, &mut coin_to_pay_mix, ts::ctx(&mut test));

        let mint_profits = app::take_profits(&admin_cap, &mut app, ts::ctx(&mut test));

        //Make sure that Mint App profits are 2 X DEFAULT_MINT_PRICE
        assert!(coin::value(&mint_profits) == DEFAULT_MINT_PRICE * 2, 666);

        let mix_profits = capy_labs::take_profits(&admin_cap, &mut capy_labs, ts::ctx(&mut test));

        //Make sure that Mint App profits are 2 X DEFAULT_MINT_PRICE
        assert!(coin::value(&mix_profits) == DEFAULT_MIX_PRICE, 667);


        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::destroy_capy(&mut app, _capy2);
        app::destroy_capy(&mut app, _mixedCapy);
        app::close_app(app);
        capy_labs::close_app(capy_labs);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        coin::burn_for_testing<SUI>(coin_to_pay2);
        coin::burn_for_testing<SUI>(coin_to_pay_mix);
        coin::burn_for_testing<SUI>(mint_profits);
        coin::burn_for_testing<SUI>(mix_profits);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::genesis::EAmountIncorrect)]
    fun test_prevent_double_spending() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        // Add necessary Genes
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        //Should FAIL here because DOUBLE SPENDING IS NOT ALLOWED!
        let _capy2 = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        let capy_labs = capy_labs::create_app(ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::destroy_capy(&mut app, _capy2);
        app::close_app(app);
        capy_labs::close_app(capy_labs);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::capy_labs::ECapyLabsNotAuthorized)]
    fun test_capy_mix_unauthorized() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        // Add necessary Genes
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        let coin_to_pay2 = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        let _capy2 = app::mint(&mut app, &clock, &mut coin_to_pay2, ts::ctx(&mut test));

        let capy_labs = capy_labs::create_app(ts::ctx(&mut test));

        let coin_to_pay_mix = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));

        //We skip Capy Labs authorization and expect mix to fail....
        let _mixedCapy = capy_labs::mix(&mut capy_labs, &mut  _capy, &mut  _capy2, &clock, &mut coin_to_pay_mix, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::destroy_capy(&mut app, _capy2);
        app::destroy_capy(&mut app, _mixedCapy);
        app::close_app(app);
        capy_labs::close_app(capy_labs);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        coin::burn_for_testing<SUI>(coin_to_pay2);
        coin::burn_for_testing<SUI>(coin_to_pay_mix);
        ts::end(test);
    }


    #[test]
    fun test_capy_mix_epoch_cooldown() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        // Add necessary Genes
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        let coin_to_pay2 = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));
        let _capy2 = app::mint(&mut app, &clock, &mut coin_to_pay2, ts::ctx(&mut test));

        let capy_labs = capy_labs::create_app(ts::ctx(&mut test));
        capy_labs::authorize<Capy>(&admin_cap, &mut capy_labs, 11,utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));

        capy_labs::add_genes<Capy>(&admin_cap,&mut capy_labs,  x"00");

        let coin_to_pay_mix = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));
        let coin_to_pay_mix2 = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));

        //Mix Capy at epoch X
        tx_context::increment_epoch_number(ts::ctx(&mut test));
        let _mixedCapy = capy_labs::mix(&mut capy_labs, &mut  _capy, &mut  _capy2, &clock, &mut coin_to_pay_mix, ts::ctx(&mut test));

        //Increase Epoch X+1
        tx_context::increment_epoch_number(ts::ctx(&mut test));

        //Mix Capy Again... This should passs
        let _mixedCapy2 = capy_labs::mix(&mut capy_labs, &mut  _mixedCapy, &mut  _capy2, &clock, &mut coin_to_pay_mix2, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::destroy_capy(&mut app, _capy2);
        app::destroy_capy(&mut app, _mixedCapy);
        app::destroy_capy(&mut app, _mixedCapy2);
        app::close_app(app);
        capy_labs::close_app(capy_labs);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        coin::burn_for_testing<SUI>(coin_to_pay2);
        coin::burn_for_testing<SUI>(coin_to_pay_mix);
        coin::burn_for_testing<SUI>(coin_to_pay_mix2);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::capy_labs::EStillInCoolDownPeriod)]
    fun test_capy_mix_epoch_cooldown_failure() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        // Add necessary Genes
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        let coin_to_pay2 = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));
        let _capy2 = app::mint(&mut app, &clock, &mut coin_to_pay2, ts::ctx(&mut test));

        let capy_labs = capy_labs::create_app(ts::ctx(&mut test));
        capy_labs::authorize<Capy>(&admin_cap, &mut capy_labs, 11,utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));

        capy_labs::add_genes<Capy>(&admin_cap,&mut capy_labs,  x"00");

        let coin_to_pay_mix = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));
        let coin_to_pay_mix2 = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));


        //Mix Capy at epoch X
        tx_context::increment_epoch_number(ts::ctx(&mut test));
        let _mixedCapy = capy_labs::mix(&mut capy_labs, &mut  _capy, &mut  _capy2, &clock, &mut coin_to_pay_mix, ts::ctx(&mut test));

        //We DO NOT Increase Epoch

        //Mix Capy Again at the same epoch... This should FAIL
        let _mixedCapy2 = capy_labs::mix(&mut capy_labs, &mut  _mixedCapy, &mut  _capy2, &clock, &mut coin_to_pay_mix2, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::destroy_capy(&mut app, _capy2);
        app::destroy_capy(&mut app, _mixedCapy);
        app::destroy_capy(&mut app, _mixedCapy2);
        app::close_app(app);
        capy_labs::close_app(capy_labs);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        coin::burn_for_testing<SUI>(coin_to_pay2);
        coin::burn_for_testing<SUI>(coin_to_pay_mix);
        coin::burn_for_testing<SUI>(coin_to_pay_mix2);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::capy_labs::EStillInCoolDownPeriod)]
    fun test_capy_mix_failure_after_cooldown_change() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        // Add necessary Genes
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        let coin_to_pay2 = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));
        let _capy2 = app::mint(&mut app, &clock, &mut coin_to_pay2, ts::ctx(&mut test));

        let capy_labs = capy_labs::create_app(ts::ctx(&mut test));
        capy_labs::authorize<Capy>(&admin_cap, &mut capy_labs, 11,utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));

        capy_labs::add_genes<Capy>(&admin_cap,&mut capy_labs,  x"00");

        let coin_to_pay_mix = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));
        let coin_to_pay_mix2 = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));


        //Mix Capy at epoch X
        tx_context::increment_epoch_number(ts::ctx(&mut test));
        let _mixedCapy = capy_labs::mix(&mut capy_labs, &mut  _capy, &mut  _capy2, &clock, &mut coin_to_pay_mix, ts::ctx(&mut test));

        //Change Cooldown period from default value to 5:
        capy_labs::set_cooldown_period(&admin_cap,&mut capy_labs,  5);

        //We Increase Epoch X+ 2
        tx_context::increment_epoch_number(ts::ctx(&mut test));
        tx_context::increment_epoch_number(ts::ctx(&mut test));

        //Mix Capy Again. Epochs increased by 2 but cooldown period = 5. So this should FAIL
        let _mixedCapy2 = capy_labs::mix(&mut capy_labs, &mut  _mixedCapy, &mut  _capy2, &clock, &mut coin_to_pay_mix2, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::destroy_capy(&mut app, _capy2);
        app::destroy_capy(&mut app, _mixedCapy);
        app::destroy_capy(&mut app, _mixedCapy2);
        app::close_app(app);
        capy_labs::close_app(capy_labs);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        coin::burn_for_testing<SUI>(coin_to_pay2);
        coin::burn_for_testing<SUI>(coin_to_pay_mix);
        coin::burn_for_testing<SUI>(coin_to_pay_mix2);
        ts::end(test);
    }


    #[test]
    fun test_capy_mix_success_after_cooldown_change() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        // Add necessary Genes
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        let coin_to_pay2 = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));
        let _capy2 = app::mint(&mut app, &clock, &mut coin_to_pay2, ts::ctx(&mut test));

        let capy_labs = capy_labs::create_app(ts::ctx(&mut test));
        capy_labs::authorize<Capy>(&admin_cap, &mut capy_labs, 11,utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));

        capy_labs::add_genes<Capy>(&admin_cap,&mut capy_labs,  x"00");

        let coin_to_pay_mix = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));
        let coin_to_pay_mix2 = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));


        //Mix Capy at epoch X
        tx_context::increment_epoch_number(ts::ctx(&mut test));
        let _mixedCapy = capy_labs::mix(&mut capy_labs, &mut  _capy, &mut  _capy2, &clock, &mut coin_to_pay_mix, ts::ctx(&mut test));

        //Change Cooldown period from default value to 3:
        capy_labs::set_cooldown_period(&admin_cap,&mut capy_labs,  3);

        //We Increase Epoch X + 3
        tx_context::increment_epoch_number(ts::ctx(&mut test));
        tx_context::increment_epoch_number(ts::ctx(&mut test));
        tx_context::increment_epoch_number(ts::ctx(&mut test));

        //Mix Capy Again. Epochs increased by 3 to match cooldown period = 3. So this should SUCCESS
        let _mixedCapy2 = capy_labs::mix(&mut capy_labs, &mut  _mixedCapy, &mut  _capy2, &clock, &mut coin_to_pay_mix2, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::destroy_capy(&mut app, _capy2);
        app::destroy_capy(&mut app, _mixedCapy);
        app::destroy_capy(&mut app, _mixedCapy2);
        app::close_app(app);
        capy_labs::close_app(capy_labs);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        coin::burn_for_testing<SUI>(coin_to_pay2);
        coin::burn_for_testing<SUI>(coin_to_pay_mix);
        coin::burn_for_testing<SUI>(coin_to_pay_mix2);
        ts::end(test);
    }


    #[test]
    #[expected_failure(abort_code = suifrens::capy_labs::EAmountIncorrect)]
    fun test_capy_mix_change_price() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        // Add necessary Genes
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));
        let coin_to_pay2 = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));
        let _capy2 = app::mint(&mut app, &clock, &mut coin_to_pay2, ts::ctx(&mut test));

        let capy_labs = capy_labs::create_app(ts::ctx(&mut test));
        capy_labs::authorize<Capy>(&admin_cap, &mut capy_labs, 11,utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));

        capy_labs::add_genes<Capy>(&admin_cap,&mut capy_labs,  x"00");

        let coin_to_pay_mix = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));
        let coin_to_pay_mix2 = coin::mint_for_testing<SUI>(DEFAULT_MIX_PRICE, ts::ctx(&mut test));

        //Mix Capy at epoch X
        tx_context::increment_epoch_number(ts::ctx(&mut test));
        let _mixedCapy = capy_labs::mix(&mut capy_labs, &mut  _capy, &mut  _capy2, &clock, &mut coin_to_pay_mix, ts::ctx(&mut test));

        //Increase Epoch X+1
        tx_context::increment_epoch_number(ts::ctx(&mut test));

        //Change Mixing price to trigger failure. We set it to some verrrry expensive
        capy_labs::set_mixing_price(&admin_cap, &mut capy_labs, 1000000000000000000);

        //Mix Capy Again... This should FAIL as the  price is > the coin balance
        let _mixedCapy2 = capy_labs::mix(&mut capy_labs, &mut  _mixedCapy, &mut  _capy2, &clock, &mut coin_to_pay_mix2, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::destroy_capy(&mut app, _capy2);
        app::destroy_capy(&mut app, _mixedCapy);
        app::destroy_capy(&mut app, _mixedCapy2);
        app::close_app(app);
        capy_labs::close_app(capy_labs);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        coin::burn_for_testing<SUI>(coin_to_pay2);
        coin::burn_for_testing<SUI>(coin_to_pay_mix);
        coin::burn_for_testing<SUI>(coin_to_pay_mix2);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::genesis::EMintNotAuthorized)]
    fun test_app_unauthorized() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Register genes anyway
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy = app::mint<Capy>(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        abort 1337
    }

    #[test]
    #[expected_failure(abort_code = suifrens::genesis::EMintNotAuthorized)]
    fun test_app_deauthorized() {
        let test = ts::begin(@0xA71CE);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, @0xA71CE);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));
        // Attach admin permission
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"cohort1"), 90000, 1000, vector::singleton(utf8(b"US")));
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Make sure a Capy can be created
        let _capy_one = app::mint<Capy>(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));
        // Then deauthorize the app
        app::deauthorize<Capy>(&admin_cap, &mut app);

        let coin_to_pay2 = coin::mint_for_testing<SUI>(DEFAULT_MINT_PRICE, ts::ctx(&mut test));

        // Aborts
        let _capy_two = app::mint<Capy>(&mut app, &clock, &mut coin_to_pay2, ts::ctx(&mut test));

        abort 1337
    }

    #[test]
    fun test_minting_price() {
        let user1 = @0x1;
        let test = ts::begin(user1);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        ts::next_tx(&mut test, user1);

        // Create Capy Manager role
        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        // Create Mint application
        let app = app::create_app(ts::ctx(&mut test));

        let mint_price = app::get_minting_price(&app);
        assert!(mint_price == DEFAULT_MINT_PRICE, 0);

        app::set_minting_price(&admin_cap, &mut app, 666);
        let new_minting_price = app::get_minting_price(&app);
        assert!(new_minting_price == 666, 0);

        sf::test_destroy_admin_cap(admin_cap);
        app::close_app(app);
        sui::clock::destroy_for_testing(clock);
        ts::end(test);
    }
}

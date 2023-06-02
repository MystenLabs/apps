// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suifrens::suifrens_unit_tests {
    use std::string::utf8;
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext, dummy};
    use sui::clock::{Self, Clock};

    use suifrens::suifrens::{Self as sf, SuiFren, AdminCap};
    use suifrens::capy::Capy;

    #[test]
    #[expected_failure(abort_code = sf::ENotAuthorized)]
    fun not_authorized_fail() {
        let (app, clock) = (app(), clock());
        let _sf = sf::mint<Capy>(&mut app, 0, vector[], vector[], &clock, &mut ctx());

        return_clock(clock);
        return_app(app);

        abort 1337
    }

    #[test]
    fun authorized_mint() {
        let (app, clock, cap) = (app(), clock(), cap());

        sf::authorize_app<Capy>(
            &cap, &mut app, utf8(b"test_app"), // app
            0, utf8(b"test_cohort"), // cohort
            clock::timestamp_ms(&clock), 100, // limits
            vector[utf8(b"AU")] // countries
        );

        let sf = sf::mint<Capy>(&mut app, 0, vector[], vector[], &clock, &mut ctx());

        return_clock(clock);
        return_app(app);
        return_cap(cap);
        return_sf(sf);
    }

    #[test]
    #[expected_failure(abort_code = sf::ENotCohortQuantityCompliant)]
    // Set limit to 1, mint 2 - expect failure
    fun authorized_mint_cap_reached_fail() {
        let (app, clock, cap) = (app(), clock(), cap());

        sf::authorize_app<Capy>(
            &cap, &mut app, utf8(b"test_app"), // app
            0, utf8(b"test_cohort"), // cohort
            clock::timestamp_ms(&clock), 1, // limits
            vector[utf8(b"AU")] // countries
        );

        let _sf = sf::mint<Capy>(&mut app, 0, vector[], vector[], &clock, &mut ctx());
        let _sf = sf::mint<Capy>(&mut app, 0, vector[], vector[], &clock, &mut ctx());

        abort 1337
    }

    #[test]
    #[expected_failure(abort_code = sf::ENotCohortTimeCompliant)]
    fun authorized_mint_time_reached_fail() {
        let (app, clock, cap) = (app(), clock(), cap());
        let curr_time = clock::timestamp_ms(&clock);

        clock::set_for_testing(&mut clock, curr_time + 1000);
        sf::authorize_app<Capy>(
            &cap, &mut app, utf8(b"test_app"), // app
            0, utf8(b"test_cohort"), // cohort
            curr_time, 1, // limits
            vector[utf8(b"AU")] // countries
        );

        // fails
        let _sf = sf::mint<Capy>(&mut app, 0, vector[], vector[], &clock, &mut ctx());

        abort 1337
    }

    #[test]
    #[expected_failure(abort_code = sf::ECountryCodesEmpty)]
    // Countries are empty - expect failure
    fun no_countries_set_fail() {
        let (app, clock, cap) = (app(), clock(), cap());
        sf::authorize_app<Capy>(
            &cap, &mut app, utf8(b"test_app"), // app
            0, utf8(b"test_cohort"), // cohort
            clock::timestamp_ms(&clock), 1, // limits
            vector[] // countries EMPTY //
        );

        // fails
        let _sf = sf::mint<Capy>(&mut app, 0, vector[], vector[], &clock, &mut ctx());

        abort 1337
    }


    fun cap(): AdminCap { sf::test_new_admin_cap(&mut ctx()) }
    fun app(): UID { object::new(&mut dummy()) }
    fun clock(): Clock { clock::create_for_testing(&mut dummy()) }
    fun ctx(): TxContext { dummy() }

    fun return_sf<T>(sf: SuiFren<T>) { sf::burn_for_testing(sf) }
    fun return_cap(cap: AdminCap) { sf::test_destroy_admin_cap(cap) }
    fun return_clock(clock: Clock) { clock::destroy_for_testing(clock) }
    fun return_app(uid: UID) { object::delete(uid) }
}

#[test_only]
/// Tests the App Cap configuration info about cohort
module suifrens::suifrens_tests {
    use std::vector;
    use sui::test_scenario as ts;
    use suifrens::capy::Capy;
    use suifrens::suifrens as sf;
    use suifrens::genesis as app;
    use sui::sui::SUI;
    use sui::coin;
    use std::string::utf8;

    #[test]
    fun test_app_cap() {
        let user1 = @0x1;
        let test = ts::begin(user1);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        ts::next_tx(&mut test, user1);

        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));

        let app = app::create_app(ts::ctx(&mut test));

        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"SUPER_COHORT"), 100, 1, vector::singleton(utf8(b"US")));
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(10000000000, ts::ctx(&mut test));

        let _capy = app::mint<Capy>(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));
        assert!(sf::birth_location(&_capy) == utf8(b"US"), 0);

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::close_app(app);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::suifrens::ENotCohortQuantityCompliant)]
    fun test_app_cap_minting_limit(){
        let user1 = @0x1;
        let test = ts::begin(user1);

        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, user1);

        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        let app = app::create_app(ts::ctx(&mut test));

        // This should fail as the limit is ZERO!
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"No_Quantity_Compliant_Cohort"), 100, 0, vector::singleton(utf8(b"US")));
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(10000000000, ts::ctx(&mut test));

        let _capy = app::mint<Capy>(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::close_app(app);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        ts::end(test);
    }


    #[test]
    #[expected_failure(abort_code = suifrens::suifrens::ENotCohortTimeCompliant)]
    fun test_app_cap_timing_limit(){
        let user1 = @0x1;
        let test = ts::begin(user1);

        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));
        ts::next_tx(&mut test, user1);

        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        let app = app::create_app(ts::ctx(&mut test));

        sui::clock::increment_for_testing(&mut clock, 51);

        // This should fail as the minting time (51) > time_limit  (50)
        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"No_Time_Compliant_Cohort"), 50, 100, vector::singleton(utf8(b"US")));
        app::add_genes<Capy>(&admin_cap, &mut app,  x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(10000000000, ts::ctx(&mut test));

        let _capy = app::mint<Capy>(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::close_app(app);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::suifrens::ECountryCodeAlreadyExists)]
    fun test_add_the_same_country_code(){
        let user1 = @0x1;
        let test = ts::begin(user1);

        ts::next_tx(&mut test, user1);

        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        let app = app::create_app(ts::ctx(&mut test));

        app::authorize<Capy>(&admin_cap, &mut app, 1, utf8(b"Cohort"), 50, 100, vector::singleton(utf8(b"US")));
        app::add_country_code<Capy>(&admin_cap, &mut app, utf8(b"US"));

        sf::test_destroy_admin_cap(admin_cap);
        app::close_app(app);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::suifrens::ECountryCodeDoesNotExist)]
    fun test_remove_not_existing_country_code(){
        let user1 = @0x1;
        let test = ts::begin(user1);

        ts::next_tx(&mut test, user1);

        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));
        let app = app::create_app(ts::ctx(&mut test));

        app::authorize<Capy>(&admin_cap, &mut app, 1, utf8(b"Cohort"), 50, 100, vector::singleton(utf8(b"US")));
        app::remove_country_code<Capy>(&admin_cap, &mut app, utf8(b"GR"));

        sf::test_destroy_admin_cap(admin_cap);
        app::close_app(app);
        ts::end(test);
    }

    #[test]
    #[expected_failure(abort_code = suifrens::suifrens::ECountryCodesEmpty)]
    fun test_pass_empty_country_code_vector(){
        let user1 = @0x1;
        let test = ts::begin(user1);
        let clock = sui::clock::create_for_testing(ts::ctx(&mut test));

        ts::next_tx(&mut test, user1);

        let admin_cap = sf::test_new_admin_cap(ts::ctx(&mut test));

        let app = app::create_app(ts::ctx(&mut test));

        app::authorize<Capy>(&admin_cap, &mut app, 11, utf8(b"SUPER_COHORT"), 100, 1, vector::empty());
        app::add_genes<Capy>(&admin_cap, &mut app, x"00");

        let coin_to_pay = coin::mint_for_testing<SUI>(10000000000, ts::ctx(&mut test));

        let _capy = app::mint<Capy>(&mut app, &clock, &mut coin_to_pay, ts::ctx(&mut test));

        sf::test_destroy_admin_cap(admin_cap);
        app::destroy_capy(&mut app, _capy);
        app::close_app(app);
        sui::clock::destroy_for_testing(clock);
        coin::burn_for_testing<SUI>(coin_to_pay);
        ts::end(test);
    }

}

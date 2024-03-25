// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// This module provides a single function to comply with the given policy and
/// complete all the required Rules in a single call.
module kiosk::ruleset {
    use sui::transfer_policy::{Self as policy, TransferRequest, TransferPolicy};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::tx_context::TxContext;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    use kiosk::kiosk_lock_rule::{Self, Rule as LockRule};
    use kiosk::floor_price_rule::{Self, Rule as FloorPriceRule};
    use kiosk::personal_kiosk_rule::{Self, Rule as PersonalKioskRule};
    use kiosk::royalty_rule::{Self, Rule as RoyaltyRule};

    public fun complete<T: key + store>(
        policy: &mut TransferPolicy<T>,
        request: TransferRequest<T>,
        kiosk: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        item: T,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        if (policy::has_rule<T, PersonalKioskRule>(policy)) {
            personal_kiosk_rule::prove(kiosk, &mut request);
        };

        if (policy::has_rule<T, RoyaltyRule>(policy)) {
            let amount = royalty_rule::fee_amount(policy, policy::paid(&request));
            let royalty = coin::split(payment, amount, ctx);
            royalty_rule::pay(policy, &mut request, royalty);
        };

        if (policy::has_rule<T, FloorPriceRule>(policy)) {
            floor_price_rule::prove(policy, &mut request);
        };

        if (policy::has_rule<T, LockRule>(policy)) {
            kiosk::lock(kiosk, kiosk_cap, policy, item);
            kiosk_lock_rule::prove(&mut request, kiosk);
        } else {
            kiosk::place(kiosk, kiosk_cap, item);
        };

        policy::confirm_request(policy, request);
    }
}

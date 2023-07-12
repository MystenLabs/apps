// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Description:
/// This module defines a Rule which sets a minimum price of sale for items of type T.
///
/// Configuration:
/// - min_price - the minimum sale price in MIST.
///
/// Use cases:
/// - Defining a minimum price for all trades of type T.
/// - Prevent trading of locked items with low pricing (e.g. by using purchase_cap).
/// 
module kiosk::floor_price_rule {
    use sui::transfer_policy::{
        Self as policy,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest
    };

    /// The sale price was lower than the minimum amount.
    const ESalePriceTooSmall: u64 = 0;

    /// The "Rule" witness to authorize the policy.
    struct Rule has drop {}

    /// Configuration for the `Floor Price Rule`.
    /// It holds the minimum price that an item can be sold at.
    /// There can't be any sales with a price < than the min_price.
    struct Config has store, drop {
        min_price: u64
    }

    /// Creator action: Add the Floor Price Rule for the `T`.
    /// Pass in the `TransferPolicy`, `TransferPolicyCap` and the `min_price`.
    public fun add<T: key + store>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
        min_price: u64
    ) {
        policy::add_rule(Rule {}, policy, cap, Config { min_price })
    }

    /// Buyer action: Checks that the sale amount is higher or equal to the min_amount.
    public fun prove<T: key + store>(
        policy: &mut TransferPolicy<T>,
        request: &mut TransferRequest<T>
    ) {
        let config: &Config = policy::get_rule(Rule {}, policy);

        assert!(policy::paid(request) >= config.min_price, ESalePriceTooSmall);
        
        policy::add_receipt(Rule {}, request)
    }
}

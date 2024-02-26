// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// The best practical approach to trading on marketplaces and favoring their
/// fees and conditions is issuing an additional `TransferRequest` (eg `Market`).
/// To achieve that, the `adapter` module provides a wrapper around the `PurchaseCap`
/// which adds an extra `Market` type parameter and forces the trade transaction
/// sender to satisfy the `TransferPolicy<Market>` requirements.
///
/// Unlike `PurchaseCap` purpose of which is to be as compatible as possible,
/// `MarketPurchaseCap` - the wrapper - only comes with a `store` to reduce the
/// amount of scenarios when it is transferred by accident or sent to an address
/// or object.
///
/// Notes:
/// - The Adapter intentionally does not have any errors built-in and the error
/// handling needs to be implemented in the extension utilizing the Marketplace
/// Adapter.
module mkt::adapter {
    use sui::transfer_policy::{Self as policy, TransferRequest};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
    use sui::tx_context::TxContext;
    use sui::object::ID;
    use sui::coin::Coin;
    use sui::sui::SUI;

    friend mkt::collection_bidding;
    friend mkt::fixed_trading;
    friend mkt::single_bid;

    /// The `NoMarket` type is used to provide a default `Market` type parameter
    /// for a scenario when the `MarketplaceAdapter` is not used and extensions
    /// maintain uniformity of emitted events. NoMarket = no marketplace.
    struct NoMarket {}

    /// The `MarketPurchaseCap` wraps the `PurchaseCap` and forces the unlocking
    /// party to satisfy the `TransferPolicy<Market>` requirements.
    struct MarketPurchaseCap<phantom T: key + store, phantom Market> has store {
        purchase_cap: PurchaseCap<T>
    }

    /// Create a new `PurchaseCap` and wrap it into the `MarketPurchaseCap`.
    public(friend) fun new<T: key + store, Market>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        item_id: ID,
        min_price: u64,
        ctx: &mut TxContext
    ): MarketPurchaseCap<T, Market> {
        MarketPurchaseCap<T, Market> {
            purchase_cap: kiosk::list_with_purchase_cap(
                kiosk, cap, item_id, min_price, ctx
            )
        }
    }

    /// Return the `MarketPurchaseCap` to the `Kiosk`. Similar to how the
    /// `PurchaseCap` can be returned at any moment. But it can't be unwrapped
    /// into the `PurchaseCap` because that would allow cheating on a `Market`.
    public(friend) fun return_cap<T: key  + store, Market>(
        kiosk: &mut Kiosk,
        cap: MarketPurchaseCap<T, Market>,
        _ctx: &mut TxContext
    ) {
        let MarketPurchaseCap { purchase_cap } = cap;
        kiosk::return_purchase_cap(kiosk, purchase_cap);
    }

    /// Use the `MarketPurchaseCap` to purchase an item from the `Kiosk`. Unlike
    /// the default flow, this function adds a `TransferRequest<Market>` which
    /// forces the unlocking party to satisfy the `TransferPolicy<Market>`
    public(friend) fun purchase<T: key + store, Market>(
        kiosk: &mut Kiosk,
        cap: MarketPurchaseCap<T, Market>,
        coin: Coin<SUI>,
        _ctx: &mut TxContext
    ): (T, TransferRequest<T>, TransferRequest<Market>) {
        let MarketPurchaseCap { purchase_cap } = cap;
        let (item, request) = kiosk::purchase_with_cap(kiosk, purchase_cap, coin);
        let market_request = policy::new_request(
            policy::item(&request),
            policy::paid(&request),
            policy::from(&request),
        );

        (item, request, market_request)
    }

    /// Purchase an item listed with "NoMarket" policy. This function ignores
    /// the `Market` type parameter and returns only a `TransferRequest<T>`.
    public(friend) fun purchase_no_market<T: key + store>(
        kiosk: &mut Kiosk,
        cap: MarketPurchaseCap<T, NoMarket>,
        coin: Coin<SUI>,
        _ctx: &mut TxContext
    ): (T, TransferRequest<T>) {
        let MarketPurchaseCap { purchase_cap } = cap;
        kiosk::purchase_with_cap(kiosk, purchase_cap, coin)
    }

    // === Getters ===

    /// Handy wrapper to read the `kiosk` field of the inner `PurchaseCap`
    public(friend) fun kiosk<T: key + store, Market>(self: &MarketPurchaseCap<T, Market>): ID {
        kiosk::purchase_cap_kiosk(&self.purchase_cap)
    }

    /// Handy wrapper to read the `item` field of the inner `PurchaseCap`
    public(friend) fun item<T: key + store, Market>(self: &MarketPurchaseCap<T, Market>): ID {
        kiosk::purchase_cap_item(&self.purchase_cap)
    }

    /// Handy wrapper to read the `min_price` field of the inner `PurchaseCap`
    public(friend) fun min_price<T: key + store, Market>(self: &MarketPurchaseCap<T, Market>): u64 {
        kiosk::purchase_cap_min_price(&self.purchase_cap)
    }

    // === Test ===

    #[test_only] friend mkt::adapter_tests;
    #[test_only] friend mkt::fixed_trading_tests;
}

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
    use sui::kiosk::{Kiosk, KioskOwnerCap, PurchaseCap};
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
    public struct NoMarket {}

    /// The `MarketPurchaseCap` wraps the `PurchaseCap` and forces the unlocking
    /// party to satisfy the `TransferPolicy<Market>` requirements.
    public struct MarketPurchaseCap<phantom Market, phantom T: key + store> has store {
        purchase_cap: PurchaseCap<T>
    }

    /// Create a new `PurchaseCap` and wrap it into the `MarketPurchaseCap`.
    public(friend) fun new<Market, T: key + store>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        item_id: ID,
        min_price: u64,
        ctx: &mut TxContext
    ): MarketPurchaseCap<Market, T> {
        let purchase_cap = kiosk.list_with_purchase_cap(
            cap, item_id, min_price, ctx
        );

        MarketPurchaseCap<Market, T> { purchase_cap }
    }

    /// Return the `MarketPurchaseCap` to the `Kiosk`. Similar to how the
    /// `PurchaseCap` can be returned at any moment. But it can't be unwrapped
    /// into the `PurchaseCap` because that would allow cheating on a `Market`.
    public(friend) fun return_cap<Market, T: key  + store>(
        kiosk: &mut Kiosk,
        cap: MarketPurchaseCap<Market, T>,
        _ctx: &mut TxContext
    ) {
        let MarketPurchaseCap { purchase_cap } = cap;
        kiosk.return_purchase_cap(purchase_cap);
    }

    /// Use the `MarketPurchaseCap` to purchase an item from the `Kiosk`. Unlike
    /// the default flow, this function adds a `TransferRequest<Market>` which
    /// forces the unlocking party to satisfy the `TransferPolicy<Market>`
    public(friend) fun purchase<Market, T: key + store>(
        kiosk: &mut Kiosk,
        cap: MarketPurchaseCap<Market, T>,
        coin: Coin<SUI>,
        _ctx: &mut TxContext
    ): (T, TransferRequest<T>, TransferRequest<Market>) {
        let MarketPurchaseCap { purchase_cap } = cap;
        let (item, request) = kiosk.purchase_with_cap(purchase_cap, coin);
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
        cap: MarketPurchaseCap<NoMarket, T>,
        coin: Coin<SUI>,
        _ctx: &mut TxContext
    ): (T, TransferRequest<T>) {
        let MarketPurchaseCap { purchase_cap } = cap;
        kiosk.purchase_with_cap(purchase_cap, coin)
    }

    // === Getters ===

    /// Handy wrapper to read the `kiosk` field of the inner `PurchaseCap`
    public(friend) fun kiosk<Market, T: key + store>(self: &MarketPurchaseCap<Market, T>): ID {
        self.purchase_cap.purchase_cap_kiosk()
    }

    /// Handy wrapper to read the `item` field of the inner `PurchaseCap`
    public(friend) fun item<Market, T: key + store>(self: &MarketPurchaseCap<Market, T>): ID {
        self.purchase_cap.purchase_cap_item()
    }

    /// Handy wrapper to read the `min_price` field of the inner `PurchaseCap`
    public(friend) fun min_price<Market, T: key + store>(self: &MarketPurchaseCap<Market, T>): u64 {
        self.purchase_cap.purchase_cap_min_price()
    }

    // === Test ===

    #[test_only] friend mkt::adapter_tests;
    #[test_only] friend mkt::fixed_trading_tests;
}

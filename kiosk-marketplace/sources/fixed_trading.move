// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This extension implements the default list-purchase flow but for a specific
/// market (using the Marketplace Adapter).
///
/// Consists of 3 functions:
/// - list
/// - delist
/// - purchase
module mkt::fixed_trading {
    use sui::kiosk::{Kiosk, KioskOwnerCap};
    use sui::transfer_policy::TransferRequest;
    use sui::tx_context::TxContext;
    use sui::object::{Self, ID};
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::event;

    use kiosk::personal_kiosk;
    use mkt::adapter::{Self as mkt, MarketPurchaseCap};
    use mkt::extension as ext;

    /// For when the caller is not the owner of the Kiosk.
    const ENotOwner: u64 = 0;
    /// Trying to purchase or delist an item that is not listed.
    const ENotListed: u64 = 1;
    /// The payment is not enough to purchase the item.
    const EIncorrectAmount: u64 = 2;

    public struct Listing<phantom Market, phantom T: key + store> has store {
        market_cap: MarketPurchaseCap<Market, T>,
        order_id: address,
    }

    // === Events ===

    /// An item has been listed on a Marketplace.
    public struct ItemListed<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        price: u64,
        order_id: address,
    }

    /// An item has been delisted from a Marketplace.
    public struct ItemDelisted<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        order_id: address,
    }

    /// An item has been purchased from a Marketplace.
    public struct ItemPurchased<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        order_id: address,
        /// The seller address if the Kiosk is personal.
        seller: address,
    }

    // === Trading Functions ===

    /// List an item on a specified Marketplace.
    public fun list<Market, T: key + store>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        item_id: ID,
        price: u64,
        ctx: &mut TxContext
    ): address {
        assert!(kiosk.has_access(cap), ENotOwner);

        let order_id = ctx.fresh_object_address();
        let market_cap = mkt::new<Market, T>(kiosk, cap, item_id, price, ctx);

        ext::storage_mut(kiosk).add(item_id, Listing {
            market_cap,
            order_id,
        });

        event::emit(ItemListed<Market, T> {
            kiosk_id: object::id(kiosk),
            order_id,
            item_id,
            price,
        });

        order_id
    }

    /// Delist an item from a specified Marketplace.
    public fun delist<Market, T: key + store>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        assert!(kiosk.has_access(cap), ENotOwner);
        assert!(kiosk.is_listed<Market, T>(item_id), ENotListed);

        let Listing { market_cap, order_id } = ext::storage_mut(kiosk).remove(item_id);
        mkt::return_cap<Market, T>(kiosk, market_cap, ctx);

        event::emit(ItemDelisted<Market, T> {
            kiosk_id: object::id(kiosk),
            order_id,
            item_id
        });
    }

    /// Purchase an item from a specified Marketplace.
    public fun purchase<Market, T: key + store>(
        kiosk: &mut Kiosk,
        item_id: ID,
        list_order_id: address,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (T, TransferRequest<T>, TransferRequest<Market>) {
        assert!(kiosk.is_listed<Market, T>(item_id), ENotListed);

        let Listing<Market, T> {
            market_cap,
            order_id
        } = ext::storage_mut(kiosk).remove(item_id);

        assert!(payment.value() == market_cap.min_price(), EIncorrectAmount);
        assert!(order_id == list_order_id, EIncorrectAmount);

        event::emit(ItemPurchased<Market, T> {
            seller: personal_kiosk::owner(kiosk),
            kiosk_id: object::id(kiosk),
            order_id,
            item_id
        });

        mkt::purchase(kiosk, market_cap, payment, ctx)
    }

    // === Getters ===

    use fun is_listed as Kiosk.is_listed;

    /// Check if an item is currently listed on a specified Marketplace.
    public fun is_listed<Market, T: key + store>(kiosk: &Kiosk, item_id: ID): bool {
        ext::storage(kiosk).contains_with_type<ID, Listing<Market, T>>(item_id)
    }

    /// Get the price of a currently listed item from a specified Marketplace.
    public fun price<Market, T: key + store>(kiosk: &Kiosk, item_id: ID): u64 {
        let Listing<Market, T> {
            market_cap,
            order_id: _
        } = ext::storage(kiosk).borrow(item_id);

        market_cap.min_price()
    }
}

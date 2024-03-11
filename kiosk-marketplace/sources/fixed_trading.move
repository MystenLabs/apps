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
    use std::option::Option;
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::TransferRequest;
    use sui::tx_context::TxContext;
    use sui::object::{Self, ID};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use sui::bag;

    use kiosk::personal_kiosk;
    use mkt::adapter::{Self as mkt, MarketPurchaseCap};
    use mkt::extension as ext;

    /// For when the caller is not the owner of the Kiosk.
    const ENotOwner: u64 = 0;
    /// Trying to purchase or delist an item that is not listed.
    const ENotListed: u64 = 1;
    /// The payment is not enough to purchase the item.
    const EIncorrectAmount: u64 = 2;

    // === Events ===

    /// An item has been listed on a Marketplace.
    public struct ItemListed<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        price: u64,
        is_personal: bool,
    }

    /// An item has been delisted from a Marketplace.
    public struct ItemDelisted<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        is_personal: bool,
    }

    /// An item has been purchased from a Marketplace.
    public struct ItemPurchased<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        /// The seller address if the Kiosk is personal.
        seller: Option<address>,
    }

    // === Trading Functions ===

    /// List an item on a specified Marketplace.
    public fun list<T: key + store, Market>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        item_id: ID,
        price: u64,
        ctx: &mut TxContext
    ) {
        assert!(kiosk.has_access(cap), ENotOwner);

        let mkt_cap = mkt::new<T, Market>(kiosk, cap, item_id, price, ctx);
        ext::storage_mut(kiosk).add(item_id, mkt_cap);

        event::emit(ItemListed<T, Market> {
            is_personal: personal_kiosk::is_personal(kiosk),
            kiosk_id: object::id(kiosk),
            item_id,
            price,
        });
    }

    /// Delist an item from a specified Marketplace.
    public fun delist<T: key + store, Market>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        assert!(kiosk.has_access(cap), ENotOwner);
        assert!(kiosk.is_listed<T, Market>(item_id), ENotListed);

        let mkt_cap = ext::storage_mut(kiosk).remove(item_id);
        mkt::return_cap<T, Market>(kiosk, mkt_cap, ctx);

        event::emit(ItemDelisted<T, Market> {
            is_personal: personal_kiosk::is_personal(kiosk),
            kiosk_id: object::id(kiosk),
            item_id
        });
    }

    /// Purchase an item from a specified Marketplace.
    public fun purchase<T: key + store, Market>(
        kiosk: &mut Kiosk,
        item_id: ID,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (T, TransferRequest<T>, TransferRequest<Market>) {
        assert!(kiosk.is_listed<T, Market>(item_id), ENotListed);

        let mkt_cap = ext::storage_mut(kiosk).remove<ID, MarketPurchaseCap<T, Market>>(item_id);
        assert!(payment.value() == mkt_cap.min_price(), EIncorrectAmount);

        event::emit(ItemPurchased<T, Market> {
            seller: personal_kiosk::try_owner(kiosk),
            kiosk_id: object::id(kiosk),
            item_id
        });

        mkt::purchase(kiosk, mkt_cap, payment, ctx)
    }

    // === Getters ===

    use fun is_listed as Kiosk.is_listed;

    /// Check if an item is currently listed on a specified Marketplace.
    public fun is_listed<T: key + store, Market>(kiosk: &Kiosk, item_id: ID): bool {
        bag::contains_with_type<ID, MarketPurchaseCap<T, Market>>(
            ext::storage(kiosk),
            item_id
        )
    }

    /// Get the price of a currently listed item from a specified Marketplace.
    public fun price<T: key + store, Market>(kiosk: &Kiosk, item_id: ID): u64 {
        let mkt_cap = bag::borrow(ext::storage(kiosk), item_id);
        mkt::min_price<T, Market>(mkt_cap)
    }
}

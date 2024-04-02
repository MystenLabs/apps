// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module for placing and managing single bids in a Kiosk. A single bid is
/// a bid for a specific item. The module provides functions to place, accept, and
/// cancel a bid.
///
/// Flow:
/// 1. A buyer places a bid for an item with a specified `ID`.
/// 2. A seller accepts the bid and sells the item to the buyer in a single action.
/// 3. The seller resolves the requests for `Market` and creator.
module mkt::single_bid {
    use sui::kiosk::{Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{TransferPolicy, TransferRequest};
    use sui::coin::{Self, Coin};
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::event;

    use mkt::extension as ext;
    use mkt::adapter as mkt;

    /// Not the kiosk owner.
    const ENotAuthorized: u64 = 0;
    /// Item is not found in the kiosk.
    const EItemNotFound: u64 = 1;
    /// Item is already listed in the kiosk.
    const EAlreadyListed: u64 = 2;
    /// Extension is not installed in the kiosk.
    const EExtensionNotInstalled: u64 = 3;
    /// No bid found for the item.
    const ENoBid: u64 = 4;
    /// Order ID mismatch
    const EOrderMismatch: u64 = 5;
    /// Extension is disabled in the kiosk.
    const EExtensionDisabled: u64 = 6;

    /// The dynamic field key for the Bid.
    public struct Bid<phantom Market, phantom T> has copy, store, drop { item_id: ID }

    public struct PlacedBid has store {
        bid: Balance<SUI>,
        order_id: address,
    }

    // === Events ===

    /// Event emitted when a bid is placed.
    public struct NewBid<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        bid: u64,
        order_id: address,
    }

    /// Event emitted when a bid is accepted.
    public struct BidAccepted<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        bid: u64,
        order_id: address,
    }

    /// Event emitted when a bid is cancelled.
    public struct BidCancelled<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        bid: u64,
        order_id: address,
    }

    // === Bidding Logic ===

    /// Place a single bid for an item with a specified `ID`.
    public fun place<T: key + store, Market>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        bid: Coin<SUI>,
        item_id: ID,
        ctx: &mut TxContext
    ): address {
        assert!(kiosk.has_access(cap), ENotAuthorized);
        assert!(ext::is_installed(kiosk), EExtensionNotInstalled);
        assert!(ext::is_enabled(kiosk), EExtensionDisabled);

        let order_id = ctx.fresh_object_address();

        event::emit(NewBid<Market, T> {
            kiosk_id: object::id(kiosk),
            bid: bid.value(),
            order_id,
            item_id,
        });

        ext::storage_mut(kiosk).add(
            Bid<Market, T> { item_id },
            PlacedBid { bid: bid.into_balance(), order_id }
        );

        order_id
    }

    /// Accept a single bid for an item with a specified `ID`. For that the
    /// seller lists and sells the item to the buyer in a single action. The
    /// requests are issued and need to be resolved by the seller.
    public fun accept<T: key + store, Market>(
        buyer: &mut Kiosk,
        seller: &mut Kiosk,
        seller_cap: &KioskOwnerCap,
        policy: &TransferPolicy<T>,
        item_id: ID,
        bid_order_id: address,
        _lock: bool,
        ctx: &mut TxContext
    ): (TransferRequest<T>, TransferRequest<Market>) {
        assert!(seller.has_access(seller_cap), ENotAuthorized);
        assert!(ext::is_installed(buyer), EExtensionNotInstalled);
        assert!(ext::is_enabled(buyer), EExtensionDisabled);
        assert!(ext::storage(buyer).contains(Bid<Market, T> { item_id }), ENoBid);
        assert!(seller.has_item(item_id), EItemNotFound);
        assert!(!seller.is_listed(item_id), EAlreadyListed);

        let PlacedBid {
            bid, order_id
        } = ext::storage_mut(buyer).remove(Bid<Market, T> { item_id });

        assert!(order_id == bid_order_id, EOrderMismatch);

        let amount = bid.value();
        let mkt_cap = mkt::new(seller, seller_cap, item_id, amount, ctx);
        let (item, req, mkt_req) = mkt::purchase(seller, mkt_cap, coin::from_balance(bid, ctx), ctx);

        event::emit(BidAccepted<Market, T> {
            kiosk_id: object::id(buyer),
            bid: amount,
            order_id,
            item_id,
        });

        ext::place_or_lock(buyer, item, policy);
        (req, mkt_req)
    }

    /// Cancel a single bid for an item with a specified `ID`.
    public fun cancel<T: key + store, Market>(
        kiosk: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        item_id: ID,
        ctx: &mut TxContext
    ): Coin<SUI> {
        assert!(kiosk.has_access(kiosk_cap), ENotAuthorized);
        assert!(ext::is_installed(kiosk), EExtensionNotInstalled);
        assert!(ext::is_enabled(kiosk), EExtensionDisabled);
        assert!(ext::storage(kiosk).contains(Bid<Market, T> { item_id }), ENoBid);

        let PlacedBid {
            order_id, bid,
        } = ext::storage_mut(kiosk).remove(Bid<Market, T> { item_id });

        event::emit(BidCancelled<Market, T> {
            kiosk_id: object::id(kiosk),
            bid: bid.value(),
            order_id,
            item_id,
        });

        coin::from_balance(bid, ctx)
    }
}

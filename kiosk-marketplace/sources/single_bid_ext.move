// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

///
module mkt::single_bid_ext {
    use std::type_name;
    use sui::kiosk_extension as ext;
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{Self as policy, TransferPolicy, TransferRequest};
    use sui::tx_context::TxContext;
    use sui::object::{Self, ID};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::vec_set;
    use sui::event;
    use sui::bag;

    use kiosk::personal_kiosk;
    use kiosk::kiosk_lock_rule::Rule as LockRule;
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

    /// The dynamic field key for the Bid.
    struct Bid<phantom T, phantom Market> has copy, store, drop { item_id: ID }

    // === Events ===

    /// Event emitted when a bid is placed.
    struct NewBid<phantom T, phantom Market> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        bid: u64,
        is_personal: bool,
    }

    /// Event emitted when a bid is accepted.
    struct BidAccepted<phantom T, phantom Market> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        bid: u64,
        is_personal: bool,
    }

    /// Event emitted when a bid is cancelled.
    struct BidCancelled<phantom T, phantom Market> has copy, drop {
        kiosk_id: ID,
        item_id: ID,
        bid: u64,
        is_personal: bool,
    }

    // === Extension ===

    /// Extension permissions - `place` and `lock`.
    const PERMISSIONS: u128 = 3;

    /// The Witness for the extension.
    struct Extension has drop {}

    /// Install the extension into the Kiosk.
    public fun add(self: &mut Kiosk, cap: &KioskOwnerCap, ctx: &mut TxContext) {
        ext::add(Extension {}, self, cap, PERMISSIONS, ctx)
    }

    // === Bidding Logic ===

    /// Place a single bid for an item with a specified `ID`.
    public fun place<T: key + store, Market>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        bid: Coin<SUI>,
        item_id: ID,
        _ctx: &mut TxContext
    ) {
        assert!(kiosk::has_access(kiosk, cap), ENotAuthorized);
        assert!(ext::is_installed<Extension>(kiosk), EExtensionNotInstalled);

        event::emit(NewBid<T, Market> {
            kiosk_id: object::id(kiosk),
            bid: coin::value(&bid),
            is_personal: personal_kiosk::is_personal(kiosk),
            item_id,
        });

        bag::add(
            ext::storage_mut(Extension {}, kiosk),
            Bid<T, Market> { item_id },
            bid
        )
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
        _lock: bool,
        ctx: &mut TxContext
    ): (TransferRequest<T>, TransferRequest<Market>) {
        assert!(ext::is_installed<Extension>(buyer), EExtensionNotInstalled);
        assert!(bag::contains(ext::storage(Extension {}, buyer), Bid<T, Market> { item_id }), ENoBid);
        assert!(kiosk::has_item(seller, item_id), EItemNotFound);
        assert!(!kiosk::is_listed(seller, item_id), EAlreadyListed);

        let coin: Coin<SUI> = bag::remove(
            ext::storage_mut(Extension {}, buyer),
            Bid<T, Market> { item_id },
        );

        let amount = coin::value(&coin);
        let mkt_cap = mkt::new(seller, seller_cap, item_id, amount, ctx);
        let (item, req, mkt_req) = mkt::purchase(seller, mkt_cap, coin, ctx);

        event::emit(BidAccepted<T, Market> {
            kiosk_id: object::id(buyer),
            bid: amount,
            is_personal: personal_kiosk::is_personal(buyer),
            item_id,
        });

        place_or_lock(buyer, item, policy);
        (req, mkt_req)
    }

    /// Cancel a single bid for an item with a specified `ID`.
    public fun cancel<T: key + store, Market>(
        kiosk: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        item_id: ID,
        _ctx: &mut TxContext
    ): Coin<SUI> {
        assert!(kiosk::has_access(kiosk, kiosk_cap), ENotAuthorized);
        assert!(ext::is_installed<Extension>(kiosk), EExtensionNotInstalled);
        assert!(bag::contains(ext::storage(Extension {}, kiosk), Bid<T, Market> { item_id }), ENoBid);

        let coin: Coin<SUI> = bag::remove(
            ext::storage_mut(Extension {}, kiosk),
            Bid<T, Market> { item_id },
        );

        event::emit(BidCancelled<T, Market> {
            kiosk_id: object::id(kiosk),
            bid: coin::value(&coin),
            is_personal: personal_kiosk::is_personal(kiosk),
            item_id,
        });

        coin
    }

    // === Internal ===

    /// A helper function which either places or locks an item in the Kiosk depending
    /// on the Rules set in the `TransferPolicy`.
    fun place_or_lock<T: key + store>(kiosk: &mut Kiosk, item: T, policy: &TransferPolicy<T>) {
        let should_lock = vec_set::contains(policy::rules(policy), &type_name::get<LockRule>());
        if (should_lock) {
            ext::lock(Extension {}, kiosk, item, policy)
        } else {
            ext::place(Extension {}, kiosk, item, policy)
        };
    }
}

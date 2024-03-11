// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Implements Collection Bidding. Currently it's a Marketplace-only functionality.
///
/// Flow:
/// 1.  The bidder chooses a marketplace and calls `place_bids` with the amount
///     of coins they want to bid.
/// 2.  The seller accepts the bid using `accept_market_bid`. The bid is taken
///     by the seller and the item is placed in the buyer's (bidder's) Kiosk.
/// 3. The seller resolves the requests for `Market` and creator.
module mkt::collection_bidding {
    use std::option::Option;
    use std::type_name;
    use std::vector;
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::tx_context::TxContext;
    use sui::coin::{Self, Coin};
    use sui::transfer_policy::{
        TransferPolicy,
        TransferRequest,
    };
    use sui::sui::SUI;
    use sui::object::{Self, ID};
    use sui::event;
    use sui::pay;
    use sui::bag;

    use kiosk::personal_kiosk;
    use mkt::adapter::{Self as mkt, NoMarket};
    use mkt::extension as ext;

    /// Trying to perform an action in another user's Kiosk.
    const ENotAuthorized: u64 = 0;
    /// Trying to accept the bid in a disabled extension.
    const EExtensionDisabled: u64 = 1;
    /// Trying to accept a bid using a wrong function.
    const EIncorrectMarketArg: u64 = 2;
    /// Trying to accept a bid that does not exist.
    const EBidNotFound: u64 = 3;
    /// Trying to place a bid with no coins.
    const ENoCoinsPassed: u64 = 4;
    /// Trying to access the extension without installing it.
    const EExtensionNotInstalled: u64 = 5;
    /// Trying to accept a bid that doesn't match the seller's expectation.
    const EBidDoesntMatchExpected: u64 = 6;

    /// A key for Extension storage - a single bid on an item of type `T` on a `Market`.
    public struct Bid<phantom Market, phantom T> has copy, store, drop {}

    // === Events ===

    /// An event that is emitted when a new bid is placed.
    public struct NewBid<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        bids: vector<u64>,
        is_personal: bool,
    }

    /// An event that is emitted when a bid is accepted.
    public struct BidAccepted<phantom Market, phantom T> has copy, drop {
        seller_kiosk_id: ID,
        buyer_kiosk_id: ID,
        item_id: ID,
        amount: u64,
        buyer_is_personal: bool,
        seller_is_personal: bool,
    }

    /// An event that is emitted when a bid is canceled.
    public struct BidCanceled<phantom Market, phantom T> has copy, drop {
        kiosk_id: ID,
        kiosk_owner: Option<address>,
    }

    // === Bidding logic ===

    /// Place a bid on any item in a collection (`T`). We do not assert that all
    /// the values in the `place_bids` are identical, the amounts are emitted
    /// in the event, the order is reversed.
    ///
    /// Use `sui::pay::split_n` to prepare the Coins for the bid.
    public fun place_bids<T: key + store, Market>(
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        bids: vector<Coin<SUI>>,
        _ctx: &mut TxContext
    ) {
        assert!(bids.length() > 0, ENoCoinsPassed);
        assert!(kiosk::has_access(kiosk, cap), ENotAuthorized);
        assert!(ext::is_installed(kiosk), EExtensionNotInstalled);

        let mut amounts = vector[];
        let (mut i, count) = (0, vector::length(&bids));
        while (i < count) {
            vector::push_back(&mut amounts, vector::borrow(&bids, i).value());
            i = i + 1;
        };

        event::emit(NewBid<T, Market> {
            kiosk_id: object::id(kiosk),
            bids: amounts,
            is_personal: personal_kiosk::is_personal(kiosk)
        });

        bag::add(ext::storage_mut(kiosk), Bid<T, Market> {}, bids);
    }

    /// Cancel all bids, return the funds to the owner.
    public fun cancel_all<T: key + store, Market>(
        kiosk: &mut Kiosk, cap: &KioskOwnerCap, ctx: &mut TxContext
    ): Coin<SUI> {
        assert!(ext::is_installed(kiosk), EExtensionNotInstalled);
        assert!(kiosk::has_access(kiosk, cap), ENotAuthorized);

        event::emit(BidCanceled<T, Market> {
            kiosk_id: object::id(kiosk),
            kiosk_owner: personal_kiosk::try_owner(kiosk)
        });

        let coins = ext::storage_mut(kiosk).remove(Bid<T, Market> {});
        let mut total = coin::zero(ctx);
        pay::join_vec(&mut total, coins);
        total
    }

    /// Accept the bid and make a purchase on in the `Kiosk`.
    ///
    /// 1. The seller creates a `MarketPurchaseCap` using the Marketplace adapter,
    /// and passes the Cap to this function. The `min_price` value is the expectation
    /// of the seller. It protects them from race conditions in case the next bid
    /// is smaller than the current one and someone frontrunned the seller.
    /// See `EBidDoesntMatchExpectation` for more details on this scenario.
    ///
    /// 2. The `bid` is taken from the `source` Kiosk's extension storage and is
    /// used to purchase the item with the `MarketPurchaseCap`. Proceeds go to
    /// the `destination` Kiosk, as this Kiosk offers the `T`.
    ///
    /// 3. The item is placed in the `destination` Kiosk using the `place` or `lock`
    /// functions (see `PERMISSIONS`). The extension must be installed and enabled
    /// for this to work.
    public fun accept_market_bid<T: key + store, Market>(
        buyer: &mut Kiosk,
        seller: &mut Kiosk,
        seller_cap: &KioskOwnerCap,
        policy: &TransferPolicy<T>,
        item_id: ID,
        // for race conditions protection
        min_bid_amount: u64,
        // keeping these arguments for extendability
        _lock: bool,
        ctx: &mut TxContext
    ): (TransferRequest<T>, TransferRequest<Market>) {
        assert!(ext::is_enabled(buyer), EExtensionNotInstalled);
        assert!(kiosk::has_access(seller, seller_cap), ENotAuthorized);

        let storage = ext::storage_mut(buyer);
        assert!(storage.contains(Bid<T, Market> {}), EBidNotFound);

        // Take 1 Coin from the bag - this is our bid (bids can't be empty, we
        // make sure of it).
        let bid: Coin<SUI> = vector::pop_back(bag::borrow_mut(storage, Bid<T, Market> {}));

        assert!(bid.value() >= min_bid_amount, EBidDoesntMatchExpected);

        // If there are no bids left, remove the bag and the key from the storage.
        if (bid_count<T, Market>(buyer) == 0) {
            vector::destroy_empty<Coin<SUI>>(
                ext::storage_mut(buyer).remove(Bid<T, Market> {})
            );
        };

        let amount = bid.value();

        assert!(ext::is_enabled(buyer), EExtensionDisabled);
        // assert!(mkt::kiosk(&mkt_cap) == object::id(seller), EIncorrectKiosk);
        // assert!(mkt::min_price(&mkt_cap) <= amount, EBidDoesntMatchExpectation);
        assert!(type_name::get<Market>() != type_name::get<NoMarket>(), EIncorrectMarketArg);

        let mkt_cap = mkt::new(
            seller, seller_cap, item_id, amount, ctx
        );

        // Perform the purchase operation in the seller's Kiosk using the `Bid`.
        let (item, request, market_request) = mkt::purchase(seller, mkt_cap, bid, ctx);

        event::emit(BidAccepted<T, Market> {
            amount,
            item_id: object::id(&item),
            buyer_kiosk_id: object::id(buyer),
            seller_kiosk_id: object::id(seller),
            buyer_is_personal: personal_kiosk::is_personal(buyer),
            seller_is_personal: personal_kiosk::is_personal(seller)
        });

        // Place or lock the item in the `source` Kiosk.
        ext::place_or_lock(buyer, item, policy);

        (request, market_request)
    }

    // === Getters ===

    /// Number of bids on an item of type `T` on a `Market` in a `Kiosk`.
    public fun bid_count<T: key + store, Market>(kiosk: &Kiosk): u64 {
        let coins: &vector<Coin<SUI>> = ext::storage(kiosk)
            .borrow(Bid<T, Market> {});

        coins.length()
    }

    /// Returns the amount of the bid on an item of type `T` on a `Market`.
    /// The `NoMarket` generic can be used to check an item listed off the market.
    public fun bid_amount<T: key + store, Market>(kiosk: &Kiosk): u64 {
        let coins: &vector<Coin<SUI>> = ext::storage(kiosk).borrow(Bid<T, Market> {});
        coins.borrow(0).value()
    }
}

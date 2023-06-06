// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Accessory Store for SuiFrens. Accessory Store sells identical items
/// in the limit specified quantity or, if quantity is not set, unlimited.
///
/// Gives the Store Owner full access over the Listings and their quantity
/// as well as allows collecting profits in a single call.
module accessories::store {
    use std::option::{Self, Option};
    use std::string::String;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, ID, UID};
    use sui::balance::{Self, Balance};
    use sui::dynamic_field as df;
    use sui::tx_context::{sender, TxContext};
    use sui::event::emit;
    use sui::transfer;

    use suifrens::suifrens::AdminCap;
    use accessories::accessories::{Self, Accessory};

    /// The amount paid does not match the expected.
    const EAmountIncorrect: u64 = 0;
    /// For when the AccessoriesStore.balance is equal to zero.
    const EStoreZeroBalance: u64 = 1;
    /// For the accessories have an accessory type, but the quantity is equal to zero.
    const ENotAvailableQuantity: u64 = 2;

    /// Store for any type T. Collects profits from all sold listings
    /// to be later acquirable by the Capy Admin.
    struct AccessoriesStore has key {
        id: UID,
        balance: Balance<SUI>
    }

    /// A Capability granting the full control over the `AccessoriesStore`.
    struct AccsStoreOwnerCap has key, store { id: UID }

    /// A listing an Accessory to `AccessoriesStore`. Supply is either finite or infinite.
    struct ListedAccessory has store {
        id: UID,
        name: String,
        type: String,
        price: u64,
        quantity: Option<u64>,
    }

    /// Emitted when new accessory is purchased.
    /// Off-chain we only need to know which ID
    /// corresponds to which name to serve the data.
    struct AccessoryPurchased has copy, drop {
        id: ID,
        name: String,
        type: String
    }

    /// Create a `AccessoriesStore` and a `AccsStoreOwnerCap` for this store.
    fun init(ctx: &mut TxContext) {
        transfer::share_object(
            AccessoriesStore {
                id: object::new(ctx),
                balance: balance::zero()
            }
        );
        transfer::transfer(
            AccsStoreOwnerCap {id: object::new(ctx)},
            sender(ctx)
        )
    }

    /// Buy an Item from the `AccessoriesStore`. Pay `Coin<SUI>` and
    /// receive an `Accessory`.
    public fun buy(
        self: &mut AccessoriesStore,
        name: String,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ): Accessory {
        let listing_mut = df::borrow_mut<String, ListedAccessory>(&mut self.id, name);

        assert!(listing_mut.price <= coin::value(payment), EAmountIncorrect);
        let payment_coin = coin::split(payment, listing_mut.price, ctx);
        coin::put(&mut self.balance, payment_coin);

        // if quantity is set, make sure that it's not 0; then decrement
        if (option::is_some(&listing_mut.quantity)) {
            let q = option::borrow(&listing_mut.quantity);
            assert!(*q > 0, ENotAvailableQuantity);
            option::swap(&mut listing_mut.quantity, *q - 1);
        };
        let (name, type) = (listing_mut.name, listing_mut.type);
        let accessory = accessories::mint(&mut self.id, name, type, ctx);
        emit(AccessoryPurchased {
            id: object::id(&accessory),
            name, type,
        });

        accessory
    }

    // === Admin Functions ===

    /// Withdraw profits from the App as a single Coin
    /// Uses sender of transaction to determine storage and control access.
    public fun collect_profits(
        _: &AccsStoreOwnerCap,
        self: &mut AccessoriesStore,
        ctx: &mut TxContext
    ) : Coin<SUI> {
        let amount = balance::value(&self.balance);
        assert!(amount > 0, EStoreZeroBalance);
        // Take a transferable `Coin` from a `Balance`
        coin::take(&mut self.balance, amount, ctx)
    }

    /// List an accessory in the `AccessoriesStore` to be freely purchasable
    /// within the set quantity (if set).
    public fun add_listing(
        _: &AccsStoreOwnerCap,
        self: &mut AccessoriesStore,
        name: String,
        type: String,
        price: u64,
        quantity: Option<u64>,
        ctx: &mut TxContext
    ) {
        df::add(&mut self.id, name, ListedAccessory {
            id: object::new(ctx),
            price,
            quantity,
            name,
            type
        });
    }

    /// Remove an accessory from the `AccessoriesStore`
    public fun remove_listing(
        _: &AccsStoreOwnerCap,
        self: &mut AccessoriesStore,
        name: String
    ): ListedAccessory {
        df::remove(&mut self.id, name)
    }

    /// Change the quantity value for the listing in the `AccessoriesStore`.
    public fun set_quantity(
        _: &AccsStoreOwnerCap,
        self: &mut AccessoriesStore,
        name: String,
        quantity: u64
    ) {
        let listing_mut = df::borrow_mut<String, ListedAccessory>(&mut self.id, name);
        option::swap(&mut listing_mut.quantity, quantity);
    }

    /// Change the price for the listing in the `AccessoriesStore`.
    public fun update_price(
        _: &AccsStoreOwnerCap,
        self: &mut AccessoriesStore,
        name: String,
        price: u64,
    ) {
        let listing_mut = df::borrow_mut<String, ListedAccessory>(&mut self.id, name);
        listing_mut.price = price;
    }

    /// === ListedAccessory Fields ===

    /// Accessor for the `price` field of a `ListedAccessory`.
    public fun price(
        self: &AccessoriesStore,
        name: String
    ): u64 {
        let listing = df::borrow<String, ListedAccessory>(&self.id, name);
        listing.price
    }

    // === Authorization ===

    /// Authorize the `AccessoriesStore`.
    public fun authorize(cap: &AdminCap, self: &mut AccessoriesStore) {
        accessories::authorize_app(cap, &mut self.id);
    }

    /// Deauthorize the `AccessoriesStore`.
    public fun deauthorize(cap: &AdminCap, self: &mut AccessoriesStore) {
        accessories::deauthorize_app(cap, &mut self.id);
    }

    #[test_only]
    public fun create_app(ctx: &mut TxContext): AccessoriesStore {
        AccessoriesStore {
            id : object::new(ctx),
            balance: balance::zero()
        }
    }

    #[test_only]
    public fun close_app(self: AccessoriesStore) {
        let AccessoriesStore { id, balance: b } = self;
        object::delete(id);
        balance::destroy_for_testing(b);
    }

    #[test_only]
    public fun test_accs_store_owner_cap(ctx: &mut TxContext): AccsStoreOwnerCap {
        AccsStoreOwnerCap { id: object::new(ctx) }
    }

    #[test_only]
    public fun test_destroy_accs_store_owner_cap(cap: AccsStoreOwnerCap) {
        let AccsStoreOwnerCap { id } = cap;
        object::delete(id)
    }
}

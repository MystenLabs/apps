// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module accessories::accessories {
    use std::string::String;

    use sui::tx_context::TxContext;
    use sui::dynamic_object_field as dof;
    use sui::dynamic_field as df;
    use sui::object::{Self, UID};
    use sui::package::{Self};

    use suifrens::suifrens::{Self, AdminCap, SuiFren};

    /// Trying to remove an accessory that doesn't exist.
    const EAccessoryTypeDoesNotExist: u64 = 0;
    /// Trying to add an accessory that already exists.
    const EAccessoryTypeAlreadyExists: u64 = 1;
    /// An application is not authorized to mint.
    const ENotAuthorized: u64 = 2;

    /// OTW to create the `Publisher`.
    struct ACCESSORIES has drop {}

    /// A SuiFren Accessory, that is being purchased from the `AccessoriesStore`.
    struct Accessory has key, store {
        id: UID,
        name: String,
        type: String
    }

    /// This struct represents where the accessory is going to be mounted
    struct AccessoryKey has copy, store, drop { type: String }

    /// The key for the `MintCap` store.
    struct MintCapKey has copy, store, drop {}

    /// A capability allowing to mint new accessories. Later can be replaced
    /// by a better better solution. Not used anywhere in type signatures.
    struct MintCap has store {}

    /// Module initializer. Uses One Time Witness to create Publisher and transfer it to sender
    fun init(otw: ACCESSORIES, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx);
    }

    /// Mint a new Accessory; can only be called by authorized applications.
    public fun mint(app: &mut UID, name: String, type: String, ctx: &mut TxContext): Accessory {
        assert!(df::exists_with_type<MintCapKey, MintCap>(app, MintCapKey {}), ENotAuthorized);
        Accessory {
            id: object::new(ctx),
            name,
            type
        }
    }

    /// Add accessory to the SuiFren. Stores the accessory under the `type` key
    /// making it impossible to wear two accessories of the same type.
    public fun add<T> (sf: &mut SuiFren<T>, accessory: Accessory) {
        let uid_mut = suifrens::uid_mut(sf);
        assert!(!dof::exists_(uid_mut, AccessoryKey{ type: accessory.type }), EAccessoryTypeAlreadyExists);
        dof::add(uid_mut, AccessoryKey{ type: accessory.type }, accessory)
    }

    /// Remove accessory from the SuiFren. Removes the accessory with the given
    /// `type`. Aborts if the accessory is not found.
    public fun remove<T> (sf: &mut SuiFren<T>, type: String): Accessory {
        let uid_mut = suifrens::uid_mut(sf);
        assert!(dof::exists_(uid_mut, AccessoryKey { type }), EAccessoryTypeDoesNotExist);
        dof::remove(uid_mut, AccessoryKey { type })
    }

    // === Protected Functions ===

    /// Authorize an application to mint new accessories.
    public fun authorize_app(_: &AdminCap, app: &mut UID) {
        df::add(app, MintCapKey {}, MintCap {});
    }

    /// Deauthorize an application to mint new accessories.
    public fun deauthorize_app(_: &AdminCap, app: &mut UID) {
        let MintCap {} = df::remove(app, MintCapKey {});
    }

    // === Reads ===

    /// Accessor for the `name` field of the `Accessory`.
    public fun name(accessory: &Accessory): String {
        accessory.name
    }

    /// Accessor for the `type` field of the `Accessory`.
    public fun type(accessory: &Accessory): String {
        accessory.type
    }

    // === Functions for Testing ===
    #[test_only]
    public fun test_burn(accessory: Accessory) {
        let Accessory { id, name: _, type: _ } = accessory;
        object::delete(id);
    }
}

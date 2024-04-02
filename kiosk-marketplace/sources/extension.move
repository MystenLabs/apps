// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A single extension module for the package. Eliminates the need for separate
/// extension installation and management in every package.
module mkt::extension {
    use std::type_name;
    use sui::transfer_policy::{Self as policy, TransferPolicy};
    use sui::kiosk::{Kiosk, KioskOwnerCap};
    use sui::kiosk_extension as ext;
    use sui::bag::Bag;
    use sui::vec_set;

    use kiosk::kiosk_lock_rule::Rule as LockRule;
    use kiosk::personal_kiosk;

    /// Error code for the extension not being installed in the Kiosk.
    const ENotPersonal: u64 = 0;

    /// The extension Witness.
    public struct Extension has drop {}

    /// Place and Lock permissions.
    const PERMISSIONS: u128 = 3;

    /// Install the Marketplace Extension into the Kiosk.
    public fun add(kiosk: &mut Kiosk, cap: &KioskOwnerCap, ctx: &mut TxContext) {
        assert!(personal_kiosk::is_personal(kiosk), ENotPersonal);
        ext::add(Extension {}, kiosk, cap, PERMISSIONS, ctx)
    }

    /// Check if the extension is installed.
    public fun is_installed(kiosk: &Kiosk): bool {
        ext::is_installed<Extension>(kiosk)
    }

    /// Check if the extension is enabled.
    public fun is_enabled(kiosk: &Kiosk): bool {
        ext::is_enabled<Extension>(kiosk)
    }

    // === Friend only ===

    /// Place the item into the Kiosk.
    public(package) fun place<T: key + store>(
        kiosk: &mut Kiosk, item: T, policy: &TransferPolicy<T>
    ) {
        ext::place(Extension {}, kiosk, item, policy)
    }

    /// Lock the item in the Kiosk.
    public(package) fun lock<T: key + store>(
        kiosk: &mut Kiosk, item: T, policy: &TransferPolicy<T>
    ) {
        ext::lock(Extension {}, kiosk, item, policy)
    }

    /// Get the reference to the extension storage.
    public(package) fun storage(kiosk: &Kiosk): &Bag {
        ext::storage(Extension {}, kiosk)
    }

    /// Get the mutable reference to the extension storage.
    public(package) fun storage_mut(kiosk: &mut Kiosk): &mut Bag {
        ext::storage_mut(Extension {}, kiosk)
    }

    /// Place or Lock the item into the Kiosk, based on the policy.
    public(package) fun place_or_lock<T: key + store>(
        kiosk: &mut Kiosk, item: T, policy: &TransferPolicy<T>
    ) {
        let should_lock = vec_set::contains(
            policy::rules(policy),
            &type_name::get<LockRule>()
        );

        if (should_lock) {
            lock(kiosk, item, policy)
        } else {
            place(kiosk, item, policy)
        };
    }
}

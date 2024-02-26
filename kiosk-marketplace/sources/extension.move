// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A single extension module for the package. Eliminates the need for separate
/// extension installation and management in every package.
module mkt::extension {
    use sui::transfer_policy::TransferPolicy;
    use sui::kiosk::{Kiosk, KioskOwnerCap};
    use sui::kiosk_extension as ext;
    use sui::tx_context::TxContext;
    use sui::bag::Bag;

    friend mkt::collection_bidding;
    friend mkt::fixed_trading;
    friend mkt::single_bid;

    /// The extension Witness.
    struct Extension has drop {}

    /// Place and Lock permissions.
    const PERMISSIONS: u128 = 3;

    /// Install the Marketplace Extension into the Kiosk.
    public fun add(
        kiosk: &mut Kiosk, cap: &KioskOwnerCap, ctx: &mut TxContext
    ) {
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
    public(friend) fun place<T: key + store>(
        kiosk: &mut Kiosk, item: T, policy: &TransferPolicy<T>
    ) {
        ext::place(Extension {}, kiosk, item, policy)
    }

    /// Lock the item in the Kiosk.
    public(friend) fun lock<T: key + store>(
        kiosk: &mut Kiosk, item: T, policy: &TransferPolicy<T>
    ) {
        ext::lock(Extension {}, kiosk, item, policy)
    }

    /// Get the reference to the extension storage.
    public(friend) fun storage(kiosk: &Kiosk): &Bag {
        ext::storage(Extension {}, kiosk)
    }

    /// Get the mutable reference to the extension storage.
    public(friend) fun storage_mut(kiosk: &mut Kiosk): &mut Bag {
        ext::storage_mut(Extension {}, kiosk)
    }
}

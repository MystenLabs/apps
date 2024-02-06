// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// The `freezer` module provides a simple interface for freezing any object.
module freezer::freezer {
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::transfer;

    /// `Ice` is what happens to an object when it is frozen.
    struct Ice<T: key + store> has key {
        id: UID,
        obj: T,
    }

    #[allow(lint(freeze_wrapped))]
    /// Only `entry` to never be called in another module. The caller needs
    /// to make an explicit call to `freeze_object` to freeze an object.
    entry fun freeze_object<T: key + store>(obj: T, ctx: &mut TxContext) {
        transfer::freeze_object(Ice {
            id: object::new(ctx),
            obj,
        })
    }
}

// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// Notes:
/// - This application exists for demo-purposes only. Please, don't use in production.
/// - If you wish to use it as a template, remove the `#[test_only]` attribute.
///
/// This is a simple application that reads a suifren and gives some funky
/// functions to work with the SuiFren data. Who knows, they might be useful
/// someday. ;)
module sf_reader::reader {
    use sui::bcs;

    // The main module in the SuiFrens application is `suifrens`. Since the name
    // is rather long, we suggest aliasing it as `sf` for convenience.
    use suifrens::suifrens::{Self as sf, SuiFren};

    // Each SuiFren has a type parameter, all of the main types will be published
    // in the core package. The usage is similar to the `sui::sui::SUI` type (as
    // the Coin<SUI> uses).
    use suifrens::capy::Capy;

    // Sometimes the logic built around SuiFrens is generic, and does not need
    // a specific type. In this case, the function can take generic `SuiFren<T>`
    public fun genes<T>(fren: &SuiFren<T>): &vector<u8> {
        sf::genes(fren)
    }

    // Some logic might be applied to a specific type of SuiFren. In this case,
    // use the specific type. The `Capy` is the first in the Frens family.
    public fun capy_genes(fren: &SuiFren<Capy>): &vector<u8> {
        sf::genes(fren)
    }

    // SuiFren's `genes` field can be used as a source for pseudo-randomness or
    // external tooling parameters. Genes are not guaranteed to be unique - they
    // follow the Capy gene science algorithm. However, they still can be used
    // to introduce new gaming mechanics.
    //
    // This function gives a u128 read as a little-endian number from the genes.
    public fun genes_to_u128<T>(fren: &SuiFren<T>): u128 {
        let bcs = bcs::new(*genes(fren));
        bcs::peel_u128(&mut bcs)
    }
}

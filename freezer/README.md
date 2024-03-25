# Freezer

Freezer is a simple module which allows freezing any object in a safe way. Putting something on ice is a guaranteed way to keep it safe, forever!

## Why freeze objects?

> If there's a way to burn an object properly and get a storage rebate, you should do it instead. The freezer is only for object (eg TreasuryCap) which cannot be unpacked and need to be made immutable.

Sometimes, it is necessary to refrain from ownership of an object, and demonstrate it publicly. For example, if there's a Coin with a pre-minted and limited total supply, it's `TreasuryCap` may need to be frozen to demonstrate that it will never change. However, simply "freezing" an object using the `transfer::freeze_object` is a dangerous practice, since frozen capabilities can still be accessed by anyone. For that reason, the freezer module was created to provide a safe way to freeze objects and restrict access to them.

## Sui Framework Types

You can use this module for these types:

- `sui::coin::TreasuryCap<T>`
- `sui::display::Display<T>`

You **should never use this module** for these types:

- `sui::package::Publisher` - use `sui::package::burn_publisher` to unpack and get a rebate;
- `sui::package::UpgradeCap` - use `sui::package::make_immutable` to unpack and get a rebate;

## Guarantees

- A frozen object is frozen forever
- No one can access the contents of "Ice", not even by reference
- Ice can be used as a proof of freezing

## Sanity checks

- To check that this code matches its onchain version, run: `sui client verify-source`
- The UpgradeCap for the object is on Ice! [See it yourself](https://suiexplorer.com/object/0x8d82eeeaf10066a3c80a3be49affabda4be791f23400d5b7b9274f3e6c07491c)

*Even though the UpgradeCap for this package is frozen for illustration purposes, it is not recommended to freeze the UpgradeCap of a package. Instead, you should use `sui::package::make_immutable` to unpack and get a rebate.*

## Usage (only mainnet)

To use this package, you can call the `freeze_object` function and pass an object that you want to be frozen forever!

```bash
sui client call \
    --package 0xd59200b49b4ad219ad4acc1ccaa77e7f9ec199f1167d9b96cf7ea848d172ae1b \
    --module freezer \
    --function freeze_object \
    --args <OBJECT> \
    --type-args <OBJECT_TYPE> \
    --gas-budget <GAS_BUDGET>
```

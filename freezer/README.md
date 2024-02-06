# Freezer

Freezer is a simple module which allows freezing any object in a safe way. Putting something on ice is a guaranteed way to keep it safe, forever!

## Guarantees

- A frozen object is frozen forever
- No one can access the contents of "Ice", not even by reference
- Ice can be used as a proof of freezing

## Sanity checks

- To check that this code matches its onchain version, run: `sui client verify-source`
- The UpgradeCap for the object is on Ice! [See it yourself](https://suiexplorer.com/object/0x81861608525f8e7febd113783681bebaab575de2c1f986170c159b69baff8e06)

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


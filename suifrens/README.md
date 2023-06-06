# SuiFrens

This directory contains the Move sources for the [SuiFrens](https://suifrens.com/) application.

## Environments

The `main` branch contains the sources and the package currently published on **mainnet**.

The `testnet` branch contains the sources and published address on on **testnet**.

## Usage

To use SuiFrens as a dependency, add this to your Move.toml:
```
suifrens = { git = "https://github.com/MystenLabs/mysten-apps.git", subdir = "suifrens", rev = "testnet" }
```

> *For **mainnet**, use the `rev = "mainnet"` setting*

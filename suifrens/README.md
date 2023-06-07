# SuiFrens

This directory contains the Move sources for the [SuiFrens](https://suifrens.com/) application.

## Description

SuiFrens application consists of multiple packages:

- [suifrens](./suifrens) - the main package that defines the "SuiFren" type;
- [accessories](./accessories) - the package that defines the "Accessory" type and the accessory store;

## Environments

- The `main` branch contains the sources and the package currently published on **mainnet**.
- The `testnet` branch contains the sources and published address on on **testnet**.

## Usage

To use SuiFrens as a dependency, add this to your Move.toml:
```
suifrens = { git = "https://github.com/MystenLabs/apps.git", subdir = "suifrens/suifrens", rev = "testnet" }
accessories = { git = "https://github.com/MystenLabs/apps.git", subdir = "suifrens/accessories", rev = "testnet" }
```

See the [examples](../examples/) for sample applications using SuiFrens.

> *For **mainnet**, use the `rev = "mainnet"` setting*

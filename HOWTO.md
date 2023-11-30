# MystenLabs Apps Repository

This document describes the ways to use and contribute to the MystenLabs Apps Repository.

## Ground Rules

- Most of the contents of this Repository are *mirrors* of other repositories' code. Currently, the process of migration is highly manual, however this is expected to change in the future.

- This repository serves as the source of truth for currently published environments on the Sui Network.

- The `main` branch handles the latest published version on the **mainnet** environment; while the `testnet` branch is used for the **testnet** environment. Both branches are protected and require approvals from the maintainers to be updated.

- For previously published versions, the `main` and `testnet` branches need to be tagged at moment of publishing. The semver is a recommended way to tag the versions, however, due to limitations of package upgrades, no breaking change is possible, and versioning gets tricky.

- Tags must contain the version of the published package prefixed with the name of the package and the environment it is published to, eg: `suifrens-mainnnet-v0.1.0`; this way it is easier to identify the version of a specific package and the environment it was published to.

## Steps to publish a new version

1. Create a new branch from `main` or `testnet` depending on the environment you want to publish to. Testnet should always be published prior to mainnet.

2. Bump the version of the package in the `Move.toml` file, apply the changes and push the branch.

3. Create a PR to merge the branch into `main` or `testnet` depending on the environment you want to publish to. Testnet should always be published prior to mainnet.

4. Once the PR is approved and merged, create a new tag with the version you want to publish. The tag should be created from the `main` or `testnet` branch depending on the environment you want to publish to. Testnet should always be published prior to mainnet.

## Open Questions

- `CHANGELOG` for Move packages - how to handle it? Shall we create a tool that would help with that?

## Contributing

Contributions are welcome! While some of them can't be applied directly due to mirroring, they can be applied to the original repositories and then migrated here. We encourage you to open issues and PRs to discuss and propose changes.

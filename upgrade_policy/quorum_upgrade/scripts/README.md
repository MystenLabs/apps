# TypeScript Quorum Upgrade Policy Helper
This typescipt package provides the helper functions to run the different transactions
required to upgrade a contract via the **Quorum Upgrade Policy** module.
The quorum upgrade contract has been published already on the given network (mainnet or
testnet) and its package id is already defined in the script (`transaction.ts`).
Users have to define a package they want to publish and upgrade. A directory where the
package live has to be provided.

The package needs to be published (not part of this script) and the package id and
upgrade cap object id have to be defined in `transaction.ts` (`TEST_PACKAGE_ID` 
and `TEST_PACKAGE_UPGRADE_CAP_ID`).

As transactions are executed, constants have to be defined in `transaction.ts` (currently empty 
values in the source file).

## Installation
* `sui` has to be installed on the machine (https://docs.sui.io/references/cli/client 
and https://docs.sui.io/guides/developer/getting-started/sui-install) and 
the path to sui availabe to the typescript package
* run `pnpm install` from this directory (`<repo_install>/upgrade_policy/quorum_upgrade/scripts/ts`)

## Running
`transaction.ts::executeTransaction` contains all the transaction to run but they have to run one at a time as they 
produce output needed by subsequent transactions. 
So comment out the transactions that should not be executed and leave only the 1 transaction to run.
`npx ts-node src/transactions.ts` will run the transaction.

Execution should happen as follows:
1. `newQuorumUpgradeCap` needs the addresses of the voters and the upgrade package id of the package to
protect with the quorum upgrade policy. The value of `k` for the `k` out of `n` poilicy has to be
provided as well. The output of the transaction will save `QuorumUpgradeCap` on the signer address
and that object id has to be defined in `transaction.ts::QUORUM_UPGRADE_CAP_ID`
2a. the package to be upgraded is available and `transaction.ts::PATH_TO_PACKAGE` must be defined
to point to that. Please refer to https://docs.sui.io/concepts/sui-move-concepts/packages/upgrade 
for details on the upgrade logic and steps. `proposeUpgrade` can then run with the `QUORUM_UPGRADE_CAP_ID` from step 1. 
That will generate a shared `ProposedUpgrade` object whose id can be used to vote.
2b. Alternatively `proposeUpgradeV2` can then run with the `QUORUM_UPGRADE_CAP_ID` from step 1 with optional metadata `UPGRADE_METADATA` which is an object where both key and value are strings.
That will generate a shared `ProposedUpgrade` object whose id can be used to vote, and metadata attached as a dynamic field.
3a. before voting, `checkMetadata` can be called with `PROPOSED_UPGRADE_ID` to see optional metadata key-value object included with the proposed upgrade.
3b. `vote` must be called from at least `k` out of the `n` voters providing `QUORUM_UPGRADE_CAP_ID` and `VOTING_CAP_ID` of the signer. 
4. Once the quorum is reached `authorizeUpgrade` can be executed to commit the transaction.

When voting, each voter should have received the source code in a compilable form (with `toml` and in the proper directory structure) so they 
can verify the digest of the upgrade. The `ProposedUpgrade` object will contain the digest in question and that can be found via any explorer or 
by querying a node for the object and looking at the `digest` field.
Locally a `sui move build --dump-bytecode-as-base64 --path <path to upgrade>` should be run which will provide the `digest` of the upgrade 
(along with `modules` and `dependencies`) that must match the digest of the `ProposedUpgrade` on chain. That will be the source 
code to review and vote for.


import { getUpgradeDigest, getActiveAddress, prepareAddressVecSet, signAndExecute } from "./utils";
import { TransactionArgument, TransactionBlock } from '@mysten/sui.js/transactions';

// =================================================================
// Constants to update when running the different transactions
// =================================================================

// Voters. Add all addresses that will be part of the quorum policy.
const VOTER_1 = '0x754a43970ec22d78110069ca1b45fb20818348363648b6b486edf0045dea559e';
const VOTER_2 = '0xe55684e6a538d29df4b9f510a6bd3ec17d3dc47fb524839954bf7fcf835b5d0d';
const VOTER_3 = '0xe0b97bff42fcef320b5f148db69033b9f689555348b2e90f1da72b0644fa37d0';
// The package id of the `quorum_upgrade_policy` package (published on mainnet)
const QUORUM_UPGRADE_PACKAGE_ID = `0x03e8badab460af8b3d4c96b283c4c3994b370c9dd2c1a4e5f80d649c25d305da`;
const UPGRADE_METADATA: Map<string, Uint8Array> = new Map();
// Example metadata to be attached
const text = 'Hello, World!';
const encoder = new TextEncoder();
const uint8FromString = encoder.encode(text);
UPGRADE_METADATA.set('key1', uint8FromString);
UPGRADE_METADATA.set('key2', new Uint8Array([10, 11, 12]));
// The upgrade cap of the quorum upgrade policy (resulting from `quorum_upgrade_policy::new`)
const QUORUM_UPGRADE_CAP_ID = `0x8d45558b0cdd2a0590d4c148817998aeb6b8f46fd9865436a1d20c30595c7a8f`;
// path to the package to publish or upgrade
const PATH_TO_PACKAGE = '/Users/tonylee/Documents/apps/upgrade_policy/quorum_upgrade';
// The package id of the testing package to be upgraded. That is the package id of the package
// defined at the path above
const TEST_PACKAGE_ID = ``;
// The upgrade cap of the package to protect with the quorum upgrade policy
// That is the upgrade cap of the package defined at the path above
const TEST_PACKAGE_UPGRADE_CAP_ID = `0xf643c9af74a77e4435d5ed3e728756f422038844143f96c665fb9e2d4b3dfa60`;
// Voting cap used for voting.
// That is the voting cap of the transaction signer
const VOTING_CAP_ID = ``;
// Proposed upgrade.
// That is the ID of the shared object created in `quorum_upgrade_policy::propose_upgrade`
const PROPOSED_UPGRADE_ID = ``;

// =================================================================
// Transactions
// =================================================================

/// Calls `quorum_upgrade_policy::new`.
/// Run after the `quorum_upgrade_policy` package has been published.
/// After running the `QuorumUpgradeCap` will live on the address of the transaction signer.
/// All voters will receive a `VotingCap`.
const newQuorumUpgradeCap = (txb: TransactionBlock, requiredVotes: number, voters: string[], upgradeCapId: string, quorumCapHolderAddress: string) => {

    const quorumUpgradeCap = txb.moveCall({
        target: `${QUORUM_UPGRADE_PACKAGE_ID}::quorum_upgrade_policy::new`,
        arguments: [
            txb.object(upgradeCapId),
            txb.pure.u64(requiredVotes),
            prepareAddressVecSet(txb, voters)

        ]
    });

    txb.transferObjects([quorumUpgradeCap], txb.pure.address(quorumCapHolderAddress));
}

/// Calls `quorum_upgrade_policy::propose_upgrade` 
/// Calling this will publish the `ProposedUpgrade` shared object.
const proposeUpgrade = (txb: TransactionBlock, quorumUpgradeCapId: string, packagePath: string) => {
    const { digest }  = getUpgradeDigest(packagePath);

    txb.moveCall({
        target: `${QUORUM_UPGRADE_PACKAGE_ID}::quorum_upgrade_policy::propose_upgrade`,
        arguments: [
            txb.object(quorumUpgradeCapId),
            txb.pure(digest, 'vector<u8>')
        ]
    });

}

const proposeUpgradeV2 = (txb: TransactionBlock, quorumUpgradeCapId: string, packagePath: string, metadata: Map<string, Uint8Array>) => {
    const { digest }  = getUpgradeDigest(packagePath);

    const proposedUpgrade = txb.moveCall({
        target: `${QUORUM_UPGRADE_PACKAGE_ID}::quorum_upgrade_policy::propose_upgrade_v2`,
        arguments: [
            txb.object(quorumUpgradeCapId),
            txb.pure(digest, 'vector<u8>')
        ]
    });

    txb.moveCall({
        target: `${QUORUM_UPGRADE_PACKAGE_ID}::quorum_upgrade_policy::add_all_metadata`,
        arguments: [
            txb.object(proposedUpgrade),
            prepareMetadataVecMap(txb, metadata)
        ]
    });

    console.log("Proposed Upgrade Object:", proposedUpgrade);

    txb.moveCall({
        target: `${QUORUM_UPGRADE_PACKAGE_ID}::quorum_upgrade_policy::share_upgrade_object`,
        arguments: [
            txb.object(proposedUpgrade),
        ]
    });
}

const prepareMetadataVecMap = (txb: TransactionBlock, metadata: Map<string, Uint8Array>): TransactionArgument => {
    const vecMap = txb.moveCall({
        target: `0x2::vec_map::empty<string::String, vector<u8>>`,
        typeArguments: ['0x2::sui::vec_map']
    });

    metadata.forEach((value, key) => {
        txb.moveCall({
            target: `0x2::vec_map::insert`,
            arguments: [
                vecMap,
                txb.pure.string(key),
                txb.pure(value, 'vector<u8>'),
            ],
            typeArguments: ['0x1::string::String', 'vector<u8>']
        });
    });
    return vecMap;
}



/// Vote for a particular `ProposedUpgrade` shared object.
/// Use the `ProposedUpgrade` object id defined by the transaction above and the
// `VotingCap` object id of the signer as received from the `newQuorumUpgradeCap` transaction.
const vote = (txb: TransactionBlock, proposedUpgradeObjectId: string, votingCapObjectId: string) => {
    txb.moveCall({
        target: `${QUORUM_UPGRADE_PACKAGE_ID}::quorum_upgrade_policy::vote`,
        arguments: [
            txb.object(proposedUpgradeObjectId),
            txb.object(votingCapObjectId)
        ]
    });
}


/// Executes a `package upgrade`.
/// It fails if the `ProposedUpgrade` object has not reached quorum.
const authorizeUpgrade = (txb: TransactionBlock, packageId: string, proposedUpgradeObjectId: string, quorumUpgradeCapId: string, packagePath: string) => {

    const ticket = txb.moveCall({
        target: `${QUORUM_UPGRADE_PACKAGE_ID}::quorum_upgrade_policy::authorize_upgrade`,
        arguments: [
            txb.object(quorumUpgradeCapId),
            txb.object(proposedUpgradeObjectId),
        ]
    });

    const { modules, dependencies } = getUpgradeDigest(packagePath);

    const receipt = txb.upgrade({
        modules,
        dependencies,
        packageId,
        ticket,
    });

    txb.moveCall({
        target: `${QUORUM_UPGRADE_PACKAGE_ID}::quorum_upgrade_policy::commit_upgrade`,
        arguments: [
            txb.object(quorumUpgradeCapId),
            receipt
        ]
    });
}


/// Main entry points, comment out as needed...
const executeTransaction = async () => {

    const txb = new TransactionBlock();

    // // 1- define a 2 out of 3 quorum upgrade policy
    // newQuorumUpgradeCap(txb, 2, [VOTER_1, VOTER_2, VOTER_3], TEST_PACKAGE_UPGRADE_CAP_ID, getActiveAddress());

    // 2- propose an upgrade. Digest is determined automatically via the package path
    proposeUpgradeV2(txb, QUORUM_UPGRADE_CAP_ID, PATH_TO_PACKAGE, UPGRADE_METADATA);

    // // 3- vote for an upgrade
    // vote(txb, PROPOSED_UPGRADE_ID, VOTING_CAP_ID);

    // // 4- authorize/commit the upgrade
    // authorizeUpgrade(txb, TEST_PACKAGE_ID, PROPOSED_UPGRADE_ID, QUORUM_UPGRADE_CAP_ID, PATH_TO_PACKAGE);

    // Run against mainnet
    const res = await signAndExecute(txb, 'testnet');

    console.dir(res, { depth: null });
}

executeTransaction();

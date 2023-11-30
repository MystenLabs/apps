
import {TransactionBlock} from "@mysten/sui.js/transactions";
import { getUpgradeDigest, getActiveAddress, prepareAddressVecSet, signAndExecute } from "./utils";

// =================================================================
// Constants to update when running the different transactions
// =================================================================

// Voters. Add all addresses that will be part of the quorum policy.
const VOTER_1 = '';
const VOTER_2 = '';
const VOTER_3 = '';
// The package id of the `quorum_upgrade_policy` package (published on testnet)
const QUORUM_UPGRADE_PACKAGE_ID = `0x9722f37d05ba8dd7295e0828edf00849aea17411e76abc3f544ad22069cae733`; 
// The upgrade cap of the quorum upgrade policy (resulting from `quorum_upgrade_policy::new`)
const QUORUM_UPGRADE_CAP_ID = ``;
// path to the package to publish or upgrade
const PATH_TO_PACKAGE = '';
// The package id of the testing package to be upgraded. That is the package id of the package
// defined at the path above
const TEST_PACKAGE_ID = ``;
// The upgrade cap of the package to protect with the quorum upgrade policy
// That is the upgrade cap of the package defined at the path above
const TEST_PACKAGE_UPGRADE_CAP_ID = ``;
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

    // 1- define a 2 out of 3 quorum upgrade policy
    newQuorumUpgradeCap(txb, 2, [VOTER_1, VOTER_2, VOTER_3], TEST_PACKAGE_UPGRADE_CAP_ID, getActiveAddress());

    // 2- propose an upgrade. Digest is determined automatically via the package path
    proposeUpgrade(txb, QUORUM_UPGRADE_CAP_ID, PATH_TO_PACKAGE);

    // 3- vote for an upgrade
    vote(txb, PROPOSED_UPGRADE_ID, VOTING_CAP_ID);

    // 4- authorize/commit the upgrade
    authorizeUpgrade(txb, TEST_PACKAGE_ID, PROPOSED_UPGRADE_ID, QUORUM_UPGRADE_CAP_ID, PATH_TO_PACKAGE);

    // Run against testnet
    const res = await signAndExecute(txb, 'testnet');

    console.dir(res, { depth: null });
}

executeTransaction();

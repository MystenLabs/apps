import { readFileSync } from "fs";
import { homedir } from "os";
import path from "path";

import { getFullnodeUrl, SuiClient } from '@mysten/sui.js/client';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { TransactionArgument, TransactionBlock } from '@mysten/sui.js/transactions';
import { fromB64 } from '@mysten/sui.js/utils';
import { execSync } from "child_process";

export type Network = 'mainnet' | 'testnet' | 'devnet' | 'localnet'

const SUI = `sui`;


export const getActiveAddress = () => {
    return execSync(`${SUI} client active-address`, { encoding: 'utf8' }).trim();
}

/// Returns a signer based on the active address of system's sui.
export const getSigner = () => {
    const sender = getActiveAddress();

    const keystore = JSON.parse(
        readFileSync(
            path.join(homedir(), '.sui', 'sui_config', 'sui.keystore'),
            'utf8',
        )
    );

    for (const priv of keystore) {
        const raw = fromB64(priv);
        if (raw[0] !== 0) {
            continue;
        }

        const pair = Ed25519Keypair.fromSecretKey(raw.slice(1));
        if (pair.getPublicKey().toSuiAddress() === sender) {
            return pair;
        }
    }

    throw new Error(`keypair not found for sender: ${sender}`);
}

/// Executes a `sui move build --dump-bytecode-as-base64` for the specified path.
export const getUpgradeDigest = (path_name: string) => {
    return JSON.parse(
        execSync(
            `${SUI} move build --dump-bytecode-as-base64 --path ${path_name}`,
            { encoding: 'utf-8'},
        ),
    );
}

/// Get the client for the specified network.
export const getClient = (network: Network) => {
    return new SuiClient({ url: getFullnodeUrl(network) });
}

/// Construct a VecSet of addresses.
export const prepareAddressVecSet = (txb: TransactionBlock, voters: string[]): TransactionArgument => {
    const vecSet = txb.moveCall({
        target: `0x2::vec_set::empty`,
        typeArguments: ['address']
    });

    for(let voter of voters) {
        txb.moveCall({
            target: `0x2::vec_set::insert`,
            arguments: [
                vecSet,
                txb.pure.address(voter)
            ],
            typeArguments: ['address']
        });
    }

    return vecSet;
}

/// Construct a VecMap of (string, vector<u8>) key-value pairs.
export const prepareMetadataVecMap = (txb: TransactionBlock, metadata: Map<string, Uint8Array>): TransactionArgument => {
    const vecMap = txb.moveCall({
        target: `0x2::vec_map::empty`,
        typeArguments: ['0x1::string::String', 'vector<u8>']
    });

    metadata.forEach((value, key) => {
        txb.moveCall({
            target: `0x2::vec_map::insert`,
            arguments: [
                vecMap,
                txb.pure.string(key),
                txb.pure(Array.from(value), 'vector<u8>'),
            ],
            typeArguments: ['0x1::string::String', 'vector<u8>']
        });
    });
    return vecMap;
}

/// A helper to sign & execute a transaction.
export const signAndExecute = async (txb: TransactionBlock, network: Network) => {
    const client = getClient(network);
    const signer = getSigner();

    return client.signAndExecuteTransactionBlock({
        transactionBlock: txb,
        signer,
        options: {
            showEffects: true,
            showObjectChanges: true,
        }
    })
}

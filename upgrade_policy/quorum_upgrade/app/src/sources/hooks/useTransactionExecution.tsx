// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useSignTransactionBlock, useSuiClient } from '@mysten/dapp-kit';
import { SuiTransactionBlockResponse } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { isValidSuiAddress, toB64 } from '@mysten/sui.js/utils';
import { useState } from 'react';
import toast from 'react-hot-toast';

import { useMultisigAddressContext } from './useMultisigAddressContext';

export function useTransactionExecution() {
	const { isMultisig, multisigAddress } = useMultisigAddressContext();

	const client = useSuiClient();
	const { mutateAsync: signTransactionBlock } = useSignTransactionBlock();
	const [txData, setTxData] = useState<string | undefined>(undefined);

	const reset = () => {
		setTxData(undefined);
	};

	const executeTransaction = async (
		txb: TransactionBlock,
	): Promise<SuiTransactionBlockResponse | void> => {
		if (isMultisig) {
			if (!multisigAddress || !isValidSuiAddress(multisigAddress)) {
				toast.error('Please define your multi-sig address');
				return;
			}

			txb.setSender(multisigAddress);

			const txData = toB64(
				await txb.build({
					client,
				}),
			);

			setTxData(txData);
			return;
		}

		try {
			const signature = await signTransactionBlock({
				transactionBlock: txb,
			});

			const res = await client.executeTransactionBlock({
				transactionBlock: signature.transactionBlockBytes,
				signature: signature.signature,
				options: {
					showEffects: true,
					showObjectChanges: true,
				},
			});

			toast.success('Successfully executed transaction!');
			console.dir(res, { depth: null });
			return res;
		} catch (e: any) {
			toast.error(`Failed to execute transaction: ${e.message as string}`);
		}
	};

	return {
		executeTransaction,
		txData,
		reset,
	};
}

// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useSignTransaction, useSuiClient } from '@mysten/dapp-kit';
import { SuiTransactionBlockResponse } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { isValidSuiAddress, toBase64 } from '@mysten/sui/utils';
import { useState } from 'react';
import toast from 'react-hot-toast';

import { useMultisigAddressContext } from './useMultisigAddressContext';

export function useTransactionExecution() {
	const { isMultisig, multisigAddress } = useMultisigAddressContext();

	const client = useSuiClient();
	const { mutateAsync: signTransactionBlock } = useSignTransaction();
	const [txData, setTxData] = useState<string | undefined>(undefined);

	const reset = () => {
		setTxData(undefined);
	};

	const executeTransaction = async (
		txb: Transaction,
	): Promise<SuiTransactionBlockResponse | void> => {
		if (isMultisig) {
			if (!multisigAddress || !isValidSuiAddress(multisigAddress)) {
				toast.error('Please define your multi-sig address');
				return;
			}

			txb.setSender(multisigAddress);

			const txData = toBase64(
				await txb.build({
					client,
				}),
			);

			setTxData(txData);
			return;
		}

		try {
			const signature = await signTransactionBlock({
				transaction: txb,
			});

			const res = await client.executeTransactionBlock({
				transactionBlock: signature.bytes,
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

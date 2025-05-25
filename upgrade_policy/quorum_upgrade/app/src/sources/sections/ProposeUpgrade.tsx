// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useSuiClientContext, useSuiClientQuery } from '@mysten/dapp-kit';
import { SuiObjectChange, SuiParsedData } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { isValidSuiAddress, isValidSuiObjectId } from '@mysten/sui/utils';
import { InfoCircledIcon, MagnifyingGlassIcon } from '@radix-ui/react-icons';
import { Button, Flex, Grid, TextArea, TextField, Tooltip } from '@radix-ui/themes';
import { useState } from 'react';

import { InvalidObject } from '../components/InvalidObject';
import { MultisigData } from '../components/MultisigData';
import { ObjectLink } from '../components/ObjectLink';
import {
	convertObjectToQuorumUpgradeObject,
	UPGRADE_POLICY_PACKAGE_ADDRESS,
} from '../helpers/utils';
import { useActiveAddress } from '../hooks/useActiveAddress';
import { useTransactionExecution } from '../hooks/useTransactionExecution';

export function ProposeUpgrade() {
	const { network } = useSuiClientContext();
	const address = useActiveAddress();
	const [sharedObjectId, setSharedObjectId] = useState<string | undefined>(undefined);
	const [digest, setDigest] = useState<string | undefined>(undefined);
	const [result, setResult] = useState<{ message: string; objectId: string } | undefined>(
		undefined,
	);

	const { executeTransaction, txData, reset } = useTransactionExecution();

	const quorumUpgrade = useSuiClientQuery(
		'getObject',
		{
			id: sharedObjectId!,
			options: {
				showContent: true,
				showType: true,
			},
		},
		{
			enabled: !!(sharedObjectId && !!isValidSuiObjectId(sharedObjectId)),
			select(data) {
				if (!data.data) return undefined;
				return convertObjectToQuorumUpgradeObject(data.data.content as SuiParsedData, network);
			},
		},
	);

	const getValidDigest = (): Uint8Array | undefined => {
		if (!digest) return undefined;
		try {
			return Uint8Array.from([...JSON.parse(digest.trim())]);
		} catch (e) {
			console.log(e);
		}
		return undefined;
	};

	const canProposeUpgrade = () => {
		if (!sharedObjectId || !digest || !isValidSuiObjectId(sharedObjectId) || !getValidDigest())
			return false;

		return true;
	};

	const proposeUpgrade = async () => {
		setResult(undefined);
		if (!sharedObjectId || !digest || !isValidSuiObjectId(sharedObjectId) || !getValidDigest())
			return;

		const txb = new Transaction();

		txb.moveCall({
			target: `${UPGRADE_POLICY_PACKAGE_ADDRESS[network]}::quorum_upgrade_policy::propose_upgrade`,
			arguments: [
				txb.object(sharedObjectId),
				txb.pure.vector('u8', getValidDigest()!), // Digest as a vector of u8
			],
		});

		const result = await executeTransaction(txb);

		if (result) {
			const proposedUpgradeId = result.objectChanges?.find(
				(x: SuiObjectChange) =>
					x.type === 'created' && x.objectType.endsWith('::quorum_upgrade_policy::ProposedUpgrade'),
			);

			if (proposedUpgradeId && proposedUpgradeId.type === 'created') {
				setResult({
					message: 'Successfully proposed upgrade',
					objectId: proposedUpgradeId.objectId,
				});
			}
		}
	};

	if (!address || !isValidSuiAddress(address))
		return <div>Connect wallet or define multi-sig address to continue...</div>;

	return (
		<Grid gap="3">
			<TextField.Root size="3">
				<TextField.Slot>
					<MagnifyingGlassIcon height="16" width="16" />
				</TextField.Slot>
				<TextField.Input
					value={sharedObjectId}
					onChange={(e) => setSharedObjectId(e.target.value)}
					placeholder="Type in the `QuorumUpgradeCap` object ID"
					disabled={quorumUpgrade.data !== undefined}
				/>
			</TextField.Root>
			{!!sharedObjectId && !quorumUpgrade.data && !quorumUpgrade.isLoading && <InvalidObject />}

			{quorumUpgrade.data && (
				<>
					<div>
						<label className="flex gap-3 items-center mb-3">
							Type the digest for the upgrade
							<Tooltip content="You can get it by running `sui move build --dump-bytecode-as-base64` on the Smart Contract folder">
								<InfoCircledIcon />
							</Tooltip>
						</label>

						<TextArea
							value={digest}
							onChange={(e) => setDigest(e.target.value.trim())}
							disabled={!!txData || !!result?.objectId}
						/>
					</div>

					<Flex gap="5" className="flex-wrap">
						<Button
							className="cursor-pointer"
							disabled={!canProposeUpgrade() || !!result?.objectId}
							onClick={proposeUpgrade}
						>
							Propose Upgrade
						</Button>

						{txData && (
							<Button
								color="amber"
								className="cursor-pointer"
								onClick={() => {
									reset();
									setSharedObjectId(undefined);
								}}
							>
								Reset
							</Button>
						)}
					</Flex>
				</>
			)}
			{result && (
				<div className="bg-green-200 rounded-sm py-3 px-3">
					<span className="pr-3">{result?.message}</span>

					<ObjectLink objectId={result?.objectId} />
				</div>
			)}
			<MultisigData txData={txData} />
		</Grid>
	);
}

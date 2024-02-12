// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useSuiClientContext, useSuiClientQuery } from '@mysten/dapp-kit';
import { SuiObjectChange } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { isValidSuiAddress, normalizeSuiAddress } from '@mysten/sui.js/utils';
import { GridIcon, MinusIcon, PersonIcon } from '@radix-ui/react-icons';
import { Button, Flex, Grid, TextField } from '@radix-ui/themes';
import { useEffect, useState } from 'react';

import { MultisigData } from '../components/MultisigData';
import { ObjectLink } from '../components/ObjectLink';
import SelectCmp from '../components/Select';
import { prepareAddressVecSet, UPGRADE_POLICY_PACKAGE_ADDRESS } from '../helpers/utils';
import { useActiveAddress } from '../hooks/useActiveAddress';
import { useTransactionExecution } from '../hooks/useTransactionExecution';

export function NewQuorumUpgrade() {
	const { network } = useSuiClientContext();
	const address = useActiveAddress();

	const [result, setResult] = useState<{ message: string; objectId: string } | undefined>(
		undefined,
	);

	const { data, isPending, isError, error } = useSuiClientQuery('getOwnedObjects', {
		owner: address || '',
		filter: {
			StructType: `${normalizeSuiAddress('0x2')}::package::UpgradeCap`,
		},
	});

	const { executeTransaction, txData } = useTransactionExecution();

	const [selectedCap, setSelectedCap] = useState('');
	const [votesRequired, setVotesRequired] = useState<number | undefined>(undefined);
	const [addresses, setAddresses] = useState<string[]>([]);

	const addAddress = () => {
		setAddresses([...addresses, '']);
	};

	const creationDisabled = () => {
		return (
			!selectedCap ||
			!votesRequired ||
			addresses.length === 0 ||
			addresses.some((x) => !x) ||
			votesRequired > addresses.length ||
			!!result
		);
	};

	const removeAddress = (index: number) => {
		setAddresses([...addresses.slice(0, index), ...addresses.slice(index + 1)]);
	};

	useEffect(() => {
		setResult(undefined);
		setSelectedCap('');
	}, [address]);

	const createUpgradeQuorumPolicy = async () => {
		setResult(undefined);
		if (
			!selectedCap ||
			!address ||
			!votesRequired ||
			addresses.length === 0 ||
			addresses.some((x) => !x) ||
			votesRequired > addresses.length
		) {
			return;
		}
		const txb = new TransactionBlock();

		const quorumUpgradeCap = txb.moveCall({
			target: `${UPGRADE_POLICY_PACKAGE_ADDRESS[network]}::quorum_upgrade_policy::new`,
			arguments: [
				txb.object(selectedCap),
				txb.pure.u64(votesRequired),
				prepareAddressVecSet(txb, addresses),
			],
		});

		txb.transferObjects([quorumUpgradeCap], txb.pure.address(address));

		const res = await executeTransaction(txb);

		if (res) {
			const capId = res.objectChanges?.find(
				(x: SuiObjectChange) =>
					x.type === 'created' &&
					x.objectType.endsWith('::quorum_upgrade_policy::QuorumUpgradeCap'),
			);

			if (capId && capId.type === 'created') {
				setResult({
					message: 'Successfully created QuorumUpgradeCap!',
					objectId: capId.objectId,
				});
			}
		}

		console.dir(res, { depth: null });
	};

	if (!address || !isValidSuiAddress(address))
		return <div>Connect wallet or define multi-sig address to continue...</div>;
	if (isPending) return <div>Loading...</div>;
	if (isError) {
		return <div>Error: {error.message}</div>;
	}
	if (data.data.length === 0) return <div>No `UpgradeCaps` owned by the address</div>;

	return (
		<>
			<Grid gap="5" columns="1">
				<div>
					<label className="font-bold">Select an upgrade cap</label>
					<div className="pt-3">
						<SelectCmp
							selected={selectedCap}
							options={data.data.map((x) => x.data?.objectId || '')}
							setSelectedOption={setSelectedCap}
						/>
					</div>
				</div>

				<div>
					<label className="font-bold">Who are the voters?</label>
					<Grid gap="3" className="pt-3" columns="1">
						{addresses.map((address, index) => (
							<Flex className="gap-5" align="center">
								<TextField.Root size="3" key={index} className="flex-shrink-0 min-w-[75%]">
									<TextField.Slot>
										<PersonIcon height="16" width="16" />
									</TextField.Slot>
									<TextField.Input
										type="text"
										value={address}
										onInput={(e: React.ChangeEvent<HTMLInputElement>) =>
											setAddresses([
												...addresses.slice(0, index),
												e.target.value,
												...addresses.slice(index + 1),
											])
										}
										placeholder="Add another address"
									/>
								</TextField.Root>
								<Button color="red" onClick={() => removeAddress(index)} className="cursor-pointer">
									<MinusIcon />
								</Button>
							</Flex>
						))}
						<Flex className="pt-3" gap="3">
							<Button className="cursor-pointer" onClick={addAddress}>
								Add address
							</Button>
							{!addresses.includes(address) && (
								<Button
									color="gray"
									className="cursor-pointer"
									onClick={() => setAddresses([...addresses, address])}
								>
									Add my address
								</Button>
							)}
						</Flex>
					</Grid>
				</div>

				<div>
					<label className="font-bold">How many votes are required?</label>
					<TextField.Root size="3">
						<TextField.Slot>
							<GridIcon height="16" width="16" />
						</TextField.Slot>
						<TextField.Input
							type="number"
							value={votesRequired}
							onChange={(e) => setVotesRequired(Number(e.target.value))}
							placeholder="How many votes are required?"
						/>
					</TextField.Root>
				</div>

				<div>
					<Button
						className="cursor-pointer"
						disabled={creationDisabled()}
						onClick={createUpgradeQuorumPolicy}
					>
						Create Quorum Upgrade Policy
					</Button>
				</div>

				{result && (
					<div className="bg-green-200 rounded-sm py-3 px-3">
						<span className="pr-3">{result?.message}</span>

						<ObjectLink objectId={result?.objectId} />
					</div>
				)}
				<MultisigData txData={txData} />
			</Grid>
		</>
	);
}

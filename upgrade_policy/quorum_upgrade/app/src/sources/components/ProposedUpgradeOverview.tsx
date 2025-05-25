// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useSuiClientContext, useSuiClientQuery } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import { Button, Grid } from '@radix-ui/themes';

import {
	QuorumUpgradeObject,
	UPGRADE_POLICY_PACKAGE_ADDRESS,
	UpgradeProposal,
} from '../helpers/utils';
import { useActiveAddress } from '../hooks/useActiveAddress';
import { useTransactionExecution } from '../hooks/useTransactionExecution';
import { MultisigData } from './MultisigData';
import { QuorumUpgradeOverview } from './QuorumUpgradeOverview';

export function ProposedUpgradeOverview({
	proposedUpgrade,
	quorumUpgradeObject,
	refresh,
}: {
	proposedUpgrade: UpgradeProposal;
	quorumUpgradeObject: QuorumUpgradeObject;

	refresh: () => void;
}) {
	const { network } = useSuiClientContext();
	const address = useActiveAddress();

	const { executeTransaction, txData } = useTransactionExecution();

	const getOwnedVoteCap = () => {
		//@ts-ignore-next-line
		return voteCaps.data?.find((x) => x?.fields?.owner === address)?.fields;
	};

	const canVote = () => {
		return address && !!getOwnedVoteCap();
	};

	const hasVoted = () => {
		return proposedUpgrade.voters.includes(getOwnedVoteCap()?.id?.id);
	};

	const voteCaps = useSuiClientQuery(
		'multiGetObjects',
		{
			ids: quorumUpgradeObject.voterCaps,
			options: {
				showContent: true,
			},
		},
		{
			select(data) {
				if (!data) return [];
				return data.map((x) => x.data?.content!);
			},
		},
	);

	const metadata = [
		{
			title: 'Proposed Upgrade Digest',
			data: JSON.stringify(proposedUpgrade.digest),
		},
		{
			title: 'Votes',
			data: `${proposedUpgrade.voters.length} / ${quorumUpgradeObject.requiredVotes}`,
		},
		{
			title: 'Has voted',
			data: hasVoted() ? 'Yes' : 'No',
		},
		{
			title: 'Proposed by',
			data: proposedUpgrade.proposer,
		},
	];

	const vote = async () => {
		const txb = new Transaction();

		txb.moveCall({
			target: `${UPGRADE_POLICY_PACKAGE_ADDRESS[network]}::quorum_upgrade_policy::vote`,
			arguments: [txb.object(proposedUpgrade.id), txb.object(getOwnedVoteCap()?.id?.id)],
		});

		const res = await executeTransaction(txb);

		if (res) {
			voteCaps.refetch();
			refresh();
		}
	};

	return (
		<>
			<div
				className={`px-3 py-2 text-center my-3 ${
					canVote() ? (hasVoted() ? 'bg-blue-50' : 'bg-green-100') : 'bg-red-100'
				}`}
			>
				<div>
					{canVote()
						? hasVoted()
							? "You've already voted in favor of this proposal!"
							: 'You can vote for this proposal!'
						: 'You cannot vote for this proposal!'}
				</div>
			</div>

			<Grid
				gap="5"
				columns={{
					initial: '1',
					md: '2',
				}}
			>
				<div>
					{metadata.map((x) => (
						<div className="flex flex-col mb-3">
							<div className="font-bold">{x.title}</div>
							<div className="text-sm">{x.data}</div>
						</div>
					))}
				</div>
				<QuorumUpgradeOverview object={quorumUpgradeObject} />
			</Grid>

			<div>
				{canVote() && (
					<Button className="cursor-pointer" disabled={hasVoted()} onClick={vote}>
						Vote
					</Button>
				)}
			</div>

			<MultisigData txData={txData} />
		</>
	);
}

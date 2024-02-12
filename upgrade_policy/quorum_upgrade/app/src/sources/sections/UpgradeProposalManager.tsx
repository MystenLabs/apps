// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useSuiClientContext, useSuiClientQuery } from '@mysten/dapp-kit';
import { SuiParsedData } from '@mysten/sui.js/client';
import { isValidSuiObjectId } from '@mysten/sui.js/utils';
import { MagnifyingGlassIcon } from '@radix-ui/react-icons';
import { TextField } from '@radix-ui/themes';
import { useState } from 'react';

import { InvalidObject } from '../components/InvalidObject';
import { ProposedUpgradeOverview } from '../components/ProposedUpgradeOverview';
import {
	convertObjectToProposedUpgrade,
	convertObjectToQuorumUpgradeObject,
} from '../helpers/utils';

export function UpgradeProposalManager() {
	const { network } = useSuiClientContext();
	const [proposalObjectId, setProposalObjectId] = useState<string>('');

	const proposalData = useSuiClientQuery(
		'getObject',
		{
			id: proposalObjectId,
			options: {
				showContent: true,
			},
		},
		{
			enabled: !!(proposalObjectId && isValidSuiObjectId(proposalObjectId)),
			select(data) {
				if (!data.data) return undefined;
				return convertObjectToProposedUpgrade(data.data.content as SuiParsedData, network);
			},
		},
	);

	const quorumUpgradeObject = useSuiClientQuery(
		'getObject',
		{
			id: proposalData.data?.upgradeCapId!,
			options: {
				showContent: true,
			},
		},
		{
			enabled: !!proposalData.data?.upgradeCapId,
			select(data) {
				if (!data.data) return undefined;
				return convertObjectToQuorumUpgradeObject(data.data.content as SuiParsedData, network);
			},
		},
	);

	const refreshData = () => {
		proposalData.refetch();
		quorumUpgradeObject.refetch();
	};

	return (
		<div>
			<TextField.Root size="3">
				<TextField.Slot>
					<MagnifyingGlassIcon height="16" width="16" />
				</TextField.Slot>
				<TextField.Input
					value={proposalObjectId}
					onChange={(e) => setProposalObjectId(e.target.value)}
					placeholder="Type in the UpgradedProposal ID..."
					disabled={!!proposalData.data}
				/>
			</TextField.Root>

			{!!proposalObjectId && !proposalData.data && !proposalData.isLoading && (
				<div className="mt-3">
					<InvalidObject />
				</div>
			)}

			{proposalData.data && quorumUpgradeObject.data && (
				<ProposedUpgradeOverview
					proposedUpgrade={proposalData.data}
					quorumUpgradeObject={quorumUpgradeObject.data}
					refresh={refreshData}
				/>
			)}
		</div>
	);
}

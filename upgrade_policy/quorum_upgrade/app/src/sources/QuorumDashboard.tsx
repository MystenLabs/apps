// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Tabs } from '@radix-ui/themes';
import { useState } from 'react';

import { AvailableTabs } from './helpers/utils';
import { NewQuorumUpgrade } from './sections/NewQuorumUpgrade';
import { ProposeUpgrade } from './sections/ProposeUpgrade';
import { UpgradeProposalManager } from './sections/UpgradeProposalManager';

export function QuorumDashboard() {
	const [activeTab, setActiveTab] = useState<AvailableTabs>('upgrade-policy');

	const tabs = [
		{
			label: 'Vote for Proposed Upgrade',
			value: 'upgrade-policy',
			content: <UpgradeProposalManager />,
		},
		{
			label: 'Propose Upgrade',
			value: 'propose-upgrade',
			content: <ProposeUpgrade />,
		},
		{
			label: 'Convert Package to Quorum Upgrade Policy',
			value: 'new-quorum-upgrade',
			content: <NewQuorumUpgrade />,
		},
	];

	return (
		<Tabs.Root
			className="TabsRoot"
			value={activeTab}
			onValueChange={(val) => {
				setActiveTab(val as AvailableTabs);
			}}
		>
			<Tabs.List className="TabsList" aria-label="Manage quorum upgrade" size="2">
				{tabs.map((tab) => (
					<Tabs.Trigger className="TabsTrigger" value={tab.value} key={tab.value}>
						{tab.label}
					</Tabs.Trigger>
				))}
			</Tabs.List>
			{tabs.map((tab) => (
				<Tabs.Content className="TabsContent" value={tab.value} key={tab.value}>
					{tab.content}
				</Tabs.Content>
			))}
		</Tabs.Root>
	);
}

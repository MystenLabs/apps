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

	return (
		<Tabs.Root
			className="TabsRoot"
			value={activeTab}
			onValueChange={(val) => {
				setActiveTab(val as AvailableTabs);
			}}
		>
			<Tabs.List className="TabsList" aria-label="Manage quorum upgrade" size="2">
				<Tabs.Trigger className="TabsTrigger" value="upgrade-policy">
					Vote for Proposed Upgrade
				</Tabs.Trigger>
				<Tabs.Trigger className="TabsTrigger" value="propose-upgrade">
					Propose Upgrade
				</Tabs.Trigger>
				<Tabs.Trigger className="TabsTrigger" value="new-quorum-upgrade">
					Convert Package to Quorum Upgrade Policy
				</Tabs.Trigger>
			</Tabs.List>
			<Tabs.Content className="TabsContent" value="upgrade-policy">
				<UpgradeProposalManager />
			</Tabs.Content>
			<Tabs.Content className="TabsContent" value="new-quorum-upgrade">
				<NewQuorumUpgrade />
			</Tabs.Content>
			<Tabs.Content className="TabsContent" value="propose-upgrade">
				<ProposeUpgrade />
			</Tabs.Content>
		</Tabs.Root>
	);
}

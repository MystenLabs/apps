// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { QuorumUpgradeObject } from '../helpers/utils';

export function QuorumUpgradeOverview({ object }: { object: QuorumUpgradeObject }) {
	const metadata = [
		{
			title: 'Votes Required',
			data: object.requiredVotes,
		},
		{
			title: 'Eligible Voters',
			data: object.voters.map((x) => <div>{x}</div>),
		},
		{
			title: 'Eligible Vote Caps',
			data: object.voterCaps.map((x) => <div>{x}</div>),
		},
	];

	return (
		<div>
			{metadata.map((x) => (
				<div className="flex flex-col mb-3">
					<div className="font-bold">{x.title}</div>
					<div className="text-sm">{x.data}</div>
				</div>
			))}
		</div>
	);
}

// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { SuiParsedData } from '@mysten/sui/client';
import { TransactionArgument, Transaction } from '@mysten/sui/transactions';

export type AvailableTabs = 'upgrade-policy' | 'new-quorum-upgrade';

export type Network = 'mainnet' | 'testnet';

export type QuorumUpgradeObject = {
	id: string;
	upgradeCap: {
		id: string;
		version: string;
		package: string;
		policy: number;
	};
	requiredVotes: number;
	voters: string[];
	voterCaps: string[];
};

export type UpgradeProposal = {
	id: string;
	digest: [];
	voters: string[];
	proposer: string;
	upgradeCapId: string;
};

export const convertObjectToProposedUpgrade = (
	object: SuiParsedData,
	network: string,
): UpgradeProposal | undefined => {
	if (object.dataType !== 'moveObject') return undefined;

	if (
		object.type !==
		`${UPGRADE_POLICY_PACKAGE_ADDRESS[network]}::quorum_upgrade_policy::ProposedUpgrade`
	)
		return undefined;

	const fields = object.fields as { [key: string]: any };

	return {
		id: fields.id.id,
		digest: fields.digest,
		voters: fields.current_voters.fields.contents,
		proposer: fields.proposer,
		upgradeCapId: fields.upgrade_cap,
	};
};

export const convertObjectToQuorumUpgradeObject = (
	object: SuiParsedData,
	network: string,
): QuorumUpgradeObject | undefined => {
	if (object.dataType !== 'moveObject') return undefined;

	if (
		object.type !==
		`${UPGRADE_POLICY_PACKAGE_ADDRESS[network]}::quorum_upgrade_policy::QuorumUpgradeCap`
	)
		return undefined;

	const fields = object.fields as { [key: string]: any };

	return {
		id: fields.id.id,
		upgradeCap: {
			id: fields.upgrade_cap.fields.id.id,
			version: fields.upgrade_cap.version,
			package: fields.upgrade_cap.package,
			policy: fields.upgrade_cap.policy,
		},
		requiredVotes: fields.required_votes,
		voters: fields.voters.fields.contents,
		voterCaps: fields.voter_caps.fields.contents,
	};
};

export const UPGRADE_POLICY_PACKAGE_ADDRESS: Record<string, string> = {
	testnet: '0x9722f37d05ba8dd7295e0828edf00849aea17411e76abc3f544ad22069cae733',
	mainnet: '0xae627358027f3b53865d2403ecf5573c91d543a387d653764b650b8f85a2235c',
};

/// Construct a VecSet of addresses.
export const prepareAddressVecSet = (
	txb: Transaction,
	voters: string[],
): TransactionArgument => {
	const vecSet = txb.moveCall({
		target: `0x2::vec_set::empty`,
		typeArguments: ['address'],
	});

	for (let voter of voters) {
		txb.moveCall({
			target: `0x2::vec_set::insert`,
			arguments: [vecSet, txb.pure.address(voter)],
			typeArguments: ['address'],
		});
	}

	return vecSet;
};

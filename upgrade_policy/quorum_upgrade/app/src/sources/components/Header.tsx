// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { ConnectButton, useSuiClientContext } from '@mysten/dapp-kit';
import { LockClosedIcon, LockOpen1Icon } from '@radix-ui/react-icons';
import { Box, Flex, Heading, Switch, TextField } from '@radix-ui/themes';

import { MultisigSetup } from '../Contexts';
import SelectCmp from './Select';

export function Header({
	multisigSetup,
	updateMultisigSetup,
}: {
	multisigSetup: MultisigSetup;
	updateMultisigSetup: (setup: MultisigSetup) => void;
}) {
	const { network, networks, selectNetwork } = useSuiClientContext();

	return (
		<Flex
			position="sticky"
			px="4"
			py="2"
			align="center"
			justify="between"
			wrap="wrap"
			gap="2"
			style={{
				borderBottom: '1px solid var(--gray-a2)',
			}}
		>
			<Box>
				<Heading className="flex items-center justify-center gap-1">
					<LockClosedIcon height="22" width="22" className="flex-shrink-0" />
					<span className="ml-2 flex-shrink-0 mr-2">Quorum Dashboard</span>
				</Heading>
			</Box>

			<Box>
				<Flex align="center" gap="5" wrap="wrap">
					Do you want to use the tool with a multi-sig address?
					<Switch
						checked={multisigSetup.isMultisig}
						onCheckedChange={(val) =>
							updateMultisigSetup({
								...multisigSetup,
								isMultisig: val,
							})
						}
					/>
					{multisigSetup.isMultisig && (
						<div>
							<TextField.Root size="2" className="w-[350px]">
								<TextField.Slot>
									<LockOpen1Icon height="14" width="14" />
								</TextField.Slot>
								<TextField.Input
									value={multisigSetup.multisigAddress}
									onChange={(e) =>
										updateMultisigSetup({
											...multisigSetup,
											multisigAddress: e.currentTarget.value,
										})
									}
									placeholder="Enter the multi-sig address"
								/>
							</TextField.Root>
						</div>
					)}
				</Flex>
			</Box>
			<Box className="flex items-center gap-3">
				<SelectCmp
					options={Object.keys(networks)}
					selected={network}
					setSelectedOption={(val: string) => selectNetwork(val)}
				/>
				<div className="flex-shrink-0 connect-wallet-wrapper">
					<ConnectButton className="flex-shrink-0 !bg-blue-50 !shadow-none" />
				</div>
			</Box>
		</Flex>
	);
}

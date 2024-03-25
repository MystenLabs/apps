// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { CopyIcon } from '@radix-ui/react-icons';
import { Button, TextArea } from '@radix-ui/themes';
import toast from 'react-hot-toast';

import { useMultisigAddressContext } from '../hooks/useMultisigAddressContext';

export function MultisigData({ txData }: { txData: string | undefined }) {
	const { isMultisig } = useMultisigAddressContext();

	const copyToClipboard = () => {
		navigator.clipboard.writeText(txData?.trim() || '');
		toast.success('Copied to clipboard!');
	};

	return (
		<div>
			{isMultisig && txData && (
				<>
					<label>Transaction Data to sign:</label>{' '}
					<Button className="cursor-pointer" size="1" onClick={copyToClipboard}>
						<CopyIcon />
					</Button>
					<div className="mt-5">
						<div>
							<a
								href="https://multisig-toolkit.mystenlabs.com/"
								target="_blank"
								className="underline"
								rel="noreferrer"
							>
								* You can collect signatures & execute the transaction using the Multi-sig toolkit
							</a>
						</div>

						<TextArea
							className="mt-3 select-none"
							value={txData}
							rows={8}
							onClick={copyToClipboard}
						/>
					</div>
				</>
			)}
		</div>
	);
}

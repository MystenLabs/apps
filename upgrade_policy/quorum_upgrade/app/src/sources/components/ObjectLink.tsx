// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useSuiClientContext } from '@mysten/dapp-kit';
import { CopyIcon } from '@radix-ui/react-icons';
import { Button } from '@radix-ui/themes';
import toast from 'react-hot-toast';

export function ObjectLink({
	objectId,
	isAddress = false,
	...tags
}: {
	objectId: string;
	isAddress?: boolean;
} & React.HTMLAttributes<HTMLAnchorElement> &
	React.ComponentPropsWithoutRef<'a'>) {
	const { network } = useSuiClientContext();

	const link = `https://suiexplorer.com/object/${objectId}?network=${network}`;
	return (
		<>
			<span className="">
				<Button
					size="1"
					className="bg-transparent text-black cursor-pointer"
					onClick={() => {
						navigator.clipboard.writeText(objectId);
						toast.success('Copied to clipboard!');
					}}
				>
					<CopyIcon />
				</Button>
				{objectId}
			</span>

			<a href={link} target="_blank" className="underline pl-2" {...tags} rel="noreferrer">
				view on explorer
			</a>
		</>
	);
}

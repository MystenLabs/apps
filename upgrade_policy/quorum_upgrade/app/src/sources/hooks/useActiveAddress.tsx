// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useCurrentAccount } from '@mysten/dapp-kit';

import { useMultisigAddressContext } from './useMultisigAddressContext';

export function useActiveAddress() {
	const { isMultisig, multisigAddress } = useMultisigAddressContext();

	const account = useCurrentAccount();

	return isMultisig ? multisigAddress : account?.address;
}

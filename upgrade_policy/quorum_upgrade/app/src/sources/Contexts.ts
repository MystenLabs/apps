// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { createContext } from 'react';

export type MultisigSetup = {
	isMultisig: boolean;
	multisigAddress: string | undefined;
};

export const MultisigAddressContext = createContext<MultisigSetup>({
	isMultisig: false,
	multisigAddress: undefined,
});

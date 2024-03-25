// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useContext } from 'react';

import { MultisigAddressContext } from '../Contexts';

export function useMultisigAddressContext() {
	return useContext(MultisigAddressContext);
}

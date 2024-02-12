// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { Container } from '@radix-ui/themes';
import { useEffect, useState } from 'react';
import { Toaster } from 'react-hot-toast';

import { Header } from './sources/components/Header';
import { MultisigAddressContext, MultisigSetup } from './sources/Contexts';
import { LocalStorageKeys } from './sources/helpers/localStorage';
import { QuorumDashboard } from './sources/QuorumDashboard';

function App() {
	const [multisigSetup, setMultisigSetup] = useState<MultisigSetup>({
		isMultisig: false,
		multisigAddress: undefined,
	});

	const updateMultisigSetup = (setup: MultisigSetup) => {
		setMultisigSetup(setup);
		localStorage.setItem(LocalStorageKeys.MultisigSetup, JSON.stringify(setup));
	};

	// init multisig setup from local storage.
	useEffect(() => {
		const setup = localStorage.getItem(LocalStorageKeys.MultisigSetup);
		if (setup) {
			setMultisigSetup(JSON.parse(setup));
		}
	}, []);

	return (
		<MultisigAddressContext.Provider value={multisigSetup}>
			<Toaster position="bottom-center" />
			<Header multisigSetup={multisigSetup} updateMultisigSetup={updateMultisigSetup} />
			<Container>
				<Container mt="5" pt="2" px="2" style={{ background: 'var(--gray-a2)', minHeight: 700 }}>
					<QuorumDashboard />
				</Container>
			</Container>
		</MultisigAddressContext.Provider>
	);
}

export default App;

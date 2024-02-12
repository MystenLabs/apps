// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
export function InvalidObject({ message }: { message?: string }) {
	return (
		<div className="bg-red-100 px-3 py-2 rounded">
			{message ||
				'The supplied object is invalid, most likely because the type is not supported for these operations or because the address is invalid'}
		</div>
	);
}

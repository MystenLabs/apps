// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { CheckIcon, ChevronDownIcon, ChevronUpIcon } from '@radix-ui/react-icons';
import * as Select from '@radix-ui/react-select';

const SelectCmp = ({
	options = [],
	selected,
	setSelectedOption,
}: {
	options: any[];
	selected: any;
	setSelectedOption: (option: any) => void;
}) => (
	<Select.Root value={selected} onValueChange={setSelectedOption}>
		<Select.Trigger
			className="inline-flex items-center w-full text-left bg-white text-black rounded px-[15px] text-[13px] leading-none h-[35px] 
            gap-[5px] focus:shadow-black outline-none overflow-x-auto"
			aria-label="upgrade cap selector"
		>
			<Select.Value placeholder="Select an upgrade cap to continue" />
			<Select.Icon className="ml-auto">
				<ChevronDownIcon />
			</Select.Icon>
		</Select.Trigger>
		<Select.Portal>
			<Select.Content className="overflow-x-auto bg-white text-black rounded-md  max-md:max-w-[350px]">
				<Select.ScrollUpButton className="flex items-center justify-center h-[25px] cursor-default">
					<ChevronUpIcon />
				</Select.ScrollUpButton>
				<Select.Viewport className="p-[5px] ">
					<Select.Group>
						{options.map((option) => (
							<Select.Item
								className="text-[13px] leading-none cursor-pointer rounded-[3px] flex items-center h-[25px]
										pr-[35px] pl-[25px] relative select-none data-[disabled]:pointer-events-none
										data-[highlighted]:outline-none data-[highlighted]:bg-blue-50 data-[state=checked]:bg-blue-50"
								key={option}
								value={option}
							>
								<Select.ItemText>{option}</Select.ItemText>
								<Select.ItemIndicator className="absolute left-0 w-[25px] inline-flex items-center justify-center">
									<CheckIcon />
								</Select.ItemIndicator>
							</Select.Item>
						))}
					</Select.Group>
				</Select.Viewport>
				<Select.ScrollDownButton className="flex items-center justify-center h-[25px cursor-default">
					<ChevronDownIcon />
				</Select.ScrollDownButton>
			</Select.Content>
		</Select.Portal>
	</Select.Root>
);

export default SelectCmp;

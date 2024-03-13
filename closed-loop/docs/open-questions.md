# Open Questions

This document contains a list of open questions and thoughts on the topic.

## Trusting the Account Inventory

Recent developments on Kiosk illustrated that an account can not be trusted in "having" or "not having" a certain object. Because there's no way for a move function to check if user already has an object or making a request for the first time, sometimes users would game the logic of a module and re-request the same object multiple times acting as "first-timers".

While in most of the currently discovered scenarios this is not an issue, it may be a hole in the design of closed-loop token economies. Sometimes we need to guarantee that the account has only one aggregate balance and not multiple (see [Scoring Scenario](./scenarios.md#scoring)).

### Thoughts

- add another type of Action - "create balance" make a distinction between merging to an existing balance and creating a new one

## Using trusted shared balances

Current implementation disallows storing the balance. This is achieved by removing the `store` ability from the Token struct; however it is in conflict with some functionalities that involve Kiosk or potentially some other applications.

### Thoughts

- keep as is and use "from_coin" and "to_coin" to create an adapter (eg a "Kiosk Extension" for specific applications);

- consider adding a storable Token equivalent to the current one (eg. `StorableToken`), which would be used in the cases where the balance needs to be stored (eg. `Kiosk`); however this is potentially dangerous as it may lead to confusion and misuse of the two types of tokens;

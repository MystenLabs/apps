# ZkBag

ZkBag is the smart contract behind [zkSend](https://zksend.com/).

## How zkSend links work

An ephemeral address is created, whose private key is encoded on the URL.
That private key has access to "claim" anything that address owns, and in the case
of this smart contract, claim the contents of the on-chain bag.

Each object is returned by value and can be transferred with a `public_transfer` 
(or used in any other way the recipient wants to).

[Learn how to create links here](https://sdk.mystenlabs.com/zksend/link-builder)

## Goals

1. Allow the creation of claimable links with any object (not just coins)
2. Allow link regeneration
3. Keep link creation cost low
4. Make sure claim is a negative-gas* operation (that way we can sponsor all claims)
5. Avoid adding any more url parameters in the links (keep links short)
6. Claim is all-or-nothing (no partial claims of a bag)

*negative-gas operaration: The storage rebates are greater than the costs, resulting in gas rebates instead of gas spend!

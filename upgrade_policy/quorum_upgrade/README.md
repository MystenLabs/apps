# Quorum Upgrade Policy
Upgrading pacakges is a key feature of any software development. Blockchains and Sui are no different in that requirement.
Please refer to [Sui Move Concepts - Pacakges](https://docs.sui.io/concepts/sui-move-concepts/packages) for details information on publishing and upgrading of packages.<br>
However blockchain applications that manage assets have significant requirements in terms of security and safety. DeFi protocols are particularly exposed to those requirements in that they can manage a significant amount of tokens/coins for users. Moreover users may want some level of guarantees about the upgradability of a protocol they use.<br>
At the end blockchain applications or contracts should have high level of transparency over the amount of trust that is put into a given application or contract. Applications are not error free and need to evolve, users expect that and at the same time they require protection from rag pull behavior and unilateral decision on upgrades.

There is an obvious tension among those requirements, and a tension between using an immutable package which gives full guarantees over rag pull behavior, and expecting a package to evolve in order to provide more features in time and bug fixes if needed.<br>
The general expectation of a pacakge lifetime is for a package to start with a compatible upgrade policy and evolve over time into an immutable package. Steps towards immutability are going through additive only upgrades, and dependencies only upgrades. Those are well described in the [package documentation](https://docs.sui.io/concepts/sui-move-concepts/packages/custom-policies) and offer both users and developers a path towards safety and security. Moreover usage of certain type of objects (e.g. [owned objects](https://docs.sui.io/concepts/object-ownership/address-owned), [versioned shared objects](https://docs.sui.io/concepts/sui-move-concepts/packages/upgrade#versioned-shared-objects)) can help when making decisions on which application or DeFi protocol to use.

The **Quorum Upgrade Policy** package is intended to offer another level of protection for users and allow developers to give a higher level of quality over a package. The policy is a typical ***k out of n*** policy where multiple parties can vote for a proposed upgrade, and the upgrade can only be committed once a quorum is reached.<br>
We mentioned that getting into an application is a matter of trust. And that blockchain apps must make that trust as transparent as possible. The **Quorum Upgrade Policy** intends to extend the trust over an app not to a single party but to a group of known entities that can vouche for the correctness of an app and the upgrades.

## Logical Steps
When a package is first published, the publisher will receive an [UpgradeCap](https://docs.sui.io/concepts/sui-move-concepts/packages/custom-policies#upgradecap) which is the central type responsible for coordinating package upgrades. That is the object that gives the publisher the power to upgrade. That object also allows to retrieve the current latest version of the package.<br>
In order to use the **Quorum Upgrade Policy** a publisher needs to go through the following steps:
1. Determine which "entities" will be allowed to vote. Those will be addresses on Sui that should map to well known and trusted entities (e.g. auditors, reputable companies, etc.). There is a social contract at play here: we expect that in time a healthy ecosystem of trustable entities will be established. We expect **SuiNS** to play a role in that as well, by giving a clear mapping between an address and the "entity" behind it.
2. Determing the quorum required (the `k` in the `k` out of `n`).
3. Wrap the `UpgradeCap` of the package in the **Quorum Upgrade Policy** so that from that point on any upgrade must be voted according to the policy.

After those steps a user that wants to use the package has the ability (and in fact they should) to check what is the version of the package that has been protected by the policy and who are the guarantors of that policy (the voters).<br>
A healthy ecosystem will develop in time to give users a good level of trust over protocols they buy into.

Also notice that there is no incentive for a publisher to use random addresses or addresses (entities) that have not accepted the role of voters for a given package. If an entity does not know about a package and/or does not want to partecipate in voting that package can become effectively immutable as it may never reach the quorum required to upgrade. In that respect users have a guarantee that what they got into is what they are going to stick with.

In order to make an upgrade a publisher will have to go through the following steps:
1. Propose an upgrade. That implies they are going to publish a proposal with the digest of the package upgrade. The digest is effectively the hash and the unique identifier for a package, and can be determined by the source code of the package.
2. Provide the voting parties with the source code. That is a "must-do" step that will give voters a chance to review the code (the upgrade) and decide whther to vote it or not. 
3. Once the quorum is reached (enough voters have voted for the upgrade) the publisher can perform the upgrade.

A voter has the following responsibilities:
1. Must expect and require the publisher to provide the source code for the upgrade.
2. Find the digest of that upgrade and verify it is the same as the proposal (published on chain).
3. Review the source code (the upgrade) to verify correctness, security and safety.
4. Vote for the upgrade on chain.







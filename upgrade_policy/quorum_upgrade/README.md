# Quorum Upgrade Policy
Upgrading packages is a key feature of any software development. Blockchains and Sui are no
different in that requirement. Please refer to
[Sui Move Concepts - Packages](https://docs.sui.io/concepts/sui-move-concepts/packages)
for detailed information on publishing and upgrading of packages.<br>
However blockchain applications that manage assets have important requirements in terms
of security and safety. DeFi protocols are particularly exposed to those requirements, in that
they can manage a significant amount of tokens/coins for users. Moreover users may
want some level of guarantees about the upgradability of a protocol they use.<br>
At the end blockchain applications (or contracts) should have high level of transparency
over the amount of trust that is put into a given application or contract. Applications
are not error free and need to evolve, users expect that and at the same time they
require protection from rug pull behavior and unilateral decision on upgrades.

There is an obvious tension among those requirements, and a tension between using
an immutable package - which gives full guarantees over rug pull behavior - and
expecting a package to evolve in order to provide more features and bug fixes
if needed.<br>
The general expectation of a package lifetime is for a package to start with a
compatible upgrade policy and evolve over time into an immutable package.
Steps towards immutability are going through additive only upgrades, and
dependencies only upgrades. Those are well described in the
[package documentation](https://docs.sui.io/concepts/sui-move-concepts/packages/custom-policies)
and offer both users and developers a path towards safety and security.
Moreover usage of certain type of objects
(e.g. [owned objects](https://docs.sui.io/concepts/object-ownership/address-owned),
[versioned shared objects](https://docs.sui.io/concepts/sui-move-concepts/packages/upgrade#versioned-shared-objects))
can help when making decisions on which application or DeFi protocol to use.

The **Quorum Upgrade Policy** package is intended to offer another level of
protection for users, and allow developers to give a higher level of quality over a package.
The policy is a typical ***k out of n*** policy where multiple parties can vote for
a proposed upgrade, and the upgrade can only be committed once a quorum is reached.<br>
We mentioned that getting into an application is a matter of trust. And we believe blockchain
apps must make that trust as transparent as possible.
The **Quorum Upgrade Policy** intends to extend the trust over an app
not to a single party but to a group of known entities that can vouche for the
correctness of an app and the upgrades.

## Logical Steps
When a package is first published, the publisher will receive an
[UpgradeCap](https://docs.sui.io/concepts/sui-move-concepts/packages/custom-policies#upgradecap)
which is the central type responsible for coordinating package upgrades.
That is the object that gives the publisher the power to upgrade.
That object also allows to retrieve the current latest version of the package.<br>
In order to use the **Quorum Upgrade Policy** a publisher needs to go through the following steps:
1. Determine which "entities" will be allowed to vote. Those will be addresses on
Sui that should map to well known and trusted entities (e.g. auditors, reputable companies, etc.).
There is a social contract at play here: we expect that in time a healthy ecosystem
of trustable entities will be established.
We expect **SuiNS** to play a role in that as well, by giving a clear
mapping between an address and the "entity" behind it.
2. Determing the quorum required (the `k` in the `k` out of `n`).
3. Wrap the `UpgradeCap` of the package in the **Quorum Upgrade Policy** so that from that 
point on any upgrade must be voted according to the policy.

After those steps, a user that wants to use the package has the ability
(and in fact they should) to check what is the version of the package that has
been protected by the policy and who are the guarantors of that policy (the voters).<br>
A healthy ecosystem will develop in time to give users a good level of trust
over protocols they buy into.

Also notice that there is no incentive for a publisher to use random addresses
or addresses (entities) that have not accepted the role of voters for a given package.
If an entity does not know about a package and/or does not want to participate in voting
that package can become effectively immutable as it may never reach the quorum
required to upgrade. In that respect users have a guarantee that
what they get into is what they are going to stick with.

In order to make an upgrade, a publisher will have to go through the following steps:
1. Propose an upgrade. That implies they are going to publish a proposal with the
digest of the package upgrade. The digest is effectively the hash and the unique
identifier for a package, and can be determined by the source code of the package.
2. Provide the voting parties with the source code. That is a "must-do" step that will give
voters a chance to review the code (the upgrade) and decide whether to vote it or not.
3. Once the quorum is reached (enough voters have voted for the upgrade) the publisher can
perform the upgrade.

A voter has the following responsibilities:
1. Must expect and require the publisher to provide the source code for the upgrade.
2. Find the digest of that upgrade and verify it is the same as the proposal (published on chain).
3. Review the source code (the upgrade) to verify correctness, security and safety.
4. Vote for the upgrade on chain.

## Quorum Upgrade Policy Package
There are 3 main objects that play a role in a **Quorum Upgrade Policy**:
1. `QuorumUpgradeCap`: this is the capability that wraps the original `UpgradeCap` for the
package in question. That object is returned to the sender which can save it
according to its usage. The `QuorumUpgradeCap` is used for proposing and commiting an upgrade.
So whoever the proposer of the upgrade is, they must have access to a reference of
that object. Typically the package developer will own that object.
2. `VotingCap`: all registered addresses, the possible voters on the policy, will receive
a `VotingCap` that gives them the ability and rights to vote.
3. `ProposedUpgrade`: this is a proposed upgrade that will be voted. The `ProposedUpgrade`
contains the digest of the new package which can and must used to verify the code.

The API to establish the policy and to propose, vote and commit an upgrade works
as follows:
- `quorum_upgrade_policy::new` is used to create the `QuorumUpgradeCap`. 
The `UpgradeCap` of the package to protect is passed in, together with the 
`voters` as a `VecSet<address>` and the `required_votes` to establish a quorum.

The principle here is that the publisher and voters have agreed to be part of
this policy and the voters have access to the package source code.
Once the policy is established the voters can confirm that the code they
have seen and agreed on is, in fact, the code that is protected by the policy.
Any users at this point has access to that information and can verify who
the parties are and what the code is.<br>
After some time a publisher may need to upgrade the package. At which point
- `quorum_upgrade_policy::propose_upgrade` is invoked providing the `QuorumUpgradeCap`
and the `digest` of the upgrade. The `digest` is a `vector<u8>` that can be obtained
with a call to `sui move build --dump-bytecode-as-base64` against the code of
the upgrade. The result of `propose_upgrade` is the creation of a `ProposedUpgrade`
shared object that can be accessed by voters to vote for the proposal.

Publisher can also invoke `quorum_upgrade_policy::create_upgrade` providing the 
`QuorumUpgradeCap` and the `digest` of the upgrade, which returns the 
`ProposedUpgrade` object that can be passed into `quorum_upgrade_policy::add_metadata`
along with `metadata`. The `metadata` is a `VecMap<string::String, string::String>` 
which is an optional metadata field to include with the proposed_upgrade. 
Publisher can then call `quorum_upgrade_policy::share_upgrade_object` with the `ProposedUpgrade` object to share the object for voters to vote for the proposal.

At this point the publisher would provide the voter with the source code so that
each of them can run the same command (`sui move build --dump-bytecode-as-base64`)
to verify that the digest matches that of the proposal, and then review the code.
Once satisfied with the code, voters can and should vote for it
- `quorum_upgrade_policy::vote` is called passing the `ProposedUpgrade`
and the `VotingCap`. That transaction registers the vote.

Once the quorum is reached the proposer can authorize and commit the
upgrade
- `quorum_upgrade_policy::authorize_upgrade` is called providing the
`QuorumUpgradeCap` and the `ProposedUpgrade` object reference, followed by the `upgrade`
command and a call to `quorum_upgrade_policy::commit_upgrade` with the
receipt obtained by the upgrade command.
- Alternatively `quorum_upgrade_policy::authorize_upgrade_and_cleanup` is called providing 
the `QuorumUpgradeCap` and the `ProposedUpgrade` object. The process is the same as 
`authorize_upgrade` except that the shared `ProposedUpgrade` object is deleted.

After that the upgrade is live and can be used by users.

There are a set of events that can be tracked to monitor the lifetime
of an upgrade:
- `quorum_upgrade_policy::UpgradeProposed` will be emitted every time
and upgrade is proposed.
- `quorum_upgrade_policy::UpgradeVoted` will report a vote happening
against a given proposal.
- `quorum_upgrade_policy::UpgradePerformed` will indicate that the
upgrade was performed and commited.
- `quorum_upgrade_policy::UpgradeDestroyed` is emitted when the
proposal is destroyed.


## Limitation and Future 
In principle the **Quorum Upgrade Policy Package** should be immutable given
that an adversarial upgrade to that policy could comprimise the policy
itself. However we at Mysten have plan to update that code to provide
important missing features. It was critical to get the policy in place as soon
as possible in order for DeFi protocols to start using it, and to give users a
good level of safety. And we are asking developers using this policy
to trust us to provide updates that will make the policy more effective.
As soon as those updates are deployed we will make the policy itself immutable.

Right now it is not possible to change the upgrade policy to a more restrictive 
one (e.g. additive only). We feel that process should likely go through
a voting process and we plan to implement that.

It is also not possible to transfer a `VotingCap`. We think that should have
a policy as well, as allowing the `VotingCap` to be transferred freely can erode 
user trust. If a user trusts the parties involved in the policy, it does not seem 
proper to be able to switch those at will. It's possible that voting for a transfer
is all that will be required, however we are still considering the alternatives.

Shared object deletion is coming very soon, and today the policy protocol is
not as seemless as it could be if that feature was already available. In
an ideal scenario the `quorum_upgrade_policy::authorize_upgrade` should
take the `ProposedUpgrade` by value and destroy it. But that does not work
for now. As soon as shared object deletion is enabled we may decide to
provide an alternative API that does, in fact, take the `ProposedUpgrade`
by value. 

Also, and for the same reasons, `quorum_upgrade_policy::destroy_proposed_upgrade`
will not work right now. However we thought it was important to expose
that API right now so that once shared object deletion is avaiable,
`ProposedUpgrade` instances can be deleted and the storage cost recovered.

We are also considering offering an alternative way to vote in a proposal by
creating and giving voters a `Ballot` object. That `Ballot` could be
transferred and would allow someone to pass responsibilities of a vote
to a third party. However, unlike transferring a `VotingCap`, a `Ballot`
would only be responsible for a given proposal and so it feels much
less problematic that transferring the `VotingCap`.

It is not clear whether a mechanism should be provided to modify a policy
(e.g. adding or removing voters). That introduces a set of new problems
that have not been explored yet. An alternative would be to allow for a policy
to be replaced but that seems as problematic as well.

We expect to finalize the **Quorum Upgrade Policy** in the next couple of months
and make the package immutable.

It is also likely we are going to provide more policies and we welcome feedback,
and for users to provide their own story. For instance, as time locked policy upgrade
(a quorum policy with a time lock) feels important in giving user the opportunity
to get out of a contract if the upgrade is considered inappropriate for their needs.


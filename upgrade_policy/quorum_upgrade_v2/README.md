# Quorum Upgrade Policy V2

The **Quorum Upgrade Policy V2** extends the original policy with a more flexible,
modular architecture. It introduces a generic proposal system that not only handles
package upgrades but also allows voters to govern the policy itself through proposals
for adding/removing voters, updating thresholds, and more.

> ⚠️ **Why V2?** The original Quorum Upgrade Policy (V1) did not allow any modifications to the voter set or voting threshold after creation. This proved problematic in practice—if a voter lost access to their keys, left an organization, or needed to be replaced, the quorum could become permanently stuck or unable to reach consensus. V2 addresses this by making voter management a first-class, governable feature.

## Key Improvements Over V1

- **Generic Proposal System**: A unified `Proposal<T>` type that can hold different proposal data types
- **Modular Design**: Separate modules for each proposal type, making the system extensible
- **No VotingCap Required**: Voting is based on address membership in the voters set (no need to manage capability objects)
- **Self-Governance**: Voters can propose and vote on changes to the quorum itself (add/remove voters, change threshold)
- **Vote Removal**: Voters can remove their votes before a proposal is executed
- **Proposal Deletion**: Proposal creators can delete proposals they no longer want to pursue
- **Relinquish Capability**: The quorum can be dissolved and the UpgradeCap transferred to a new owner

## Core Objects

### `QuorumUpgrade`

The central shared object that wraps the original `UpgradeCap` and manages the voting configuration:

```move
public struct QuorumUpgrade has key, store {
    id: UID,
    upgrade_cap: UpgradeCap,
    required_votes: u64,
    voters: VecSet<address>,
    proposals: TableVec<ID>,
}
```

### `Proposal<T>`

A generic proposal object that can hold different types of proposal data:

```move
public struct Proposal<T> has key, store {
    id: UID,
    creator: address,
    quorum_upgrade: ID,
    votes: vector<address>,
    metadata: VecMap<String, String>,
    data: T,
}
```

## Proposal Types

The package includes several built-in proposal types:

| Module              | Proposal Type      | Description                                                |
| ------------------- | ------------------ | ---------------------------------------------------------- |
| `upgrade`           | `Upgrade`          | Propose a package upgrade with a specific digest           |
| `add_voter`         | `AddVoter`         | Add a new voter (optionally update threshold)              |
| `remove_voter`      | `RemoveVoter`      | Remove an existing voter (optionally update threshold)     |
| `replace_voter`     | `ReplaceVoter`     | Replace one voter with another                             |
| `update_threshold`  | `UpdateThreshold`  | Change the required number of votes                        |
| `relinquish_quorum` | `RelinquishQuorum` | Dissolve the quorum and transfer UpgradeCap to a new owner |

## Getting Started

### Step 1: Create the QuorumUpgrade

When a package is first published, the publisher receives an `UpgradeCap`. To use the Quorum Upgrade Policy V2:

```move
use quorum_upgrade_v2::quorum_upgrade;
use sui::vec_set;

// Create a set of voter addresses
let voters = vec_set::from_keys(vector[voter1, voter2, voter3]);

// Wrap the UpgradeCap with quorum requirements (e.g., 2 out of 3)
quorum_upgrade::new(upgrade_cap, 2, voters, ctx);
```

This creates a shared `QuorumUpgrade` object that requires 2 votes from the 3 registered voters for any proposal to pass.

### Step 2: Proposing an Upgrade

Any registered voter can propose a package upgrade:

```move
use quorum_upgrade_v2::upgrade;
use quorum_upgrade_v2::proposal;
use sui::vec_map;

// Get the digest from: sui move build --dump-bytecode-as-base64
let digest: vector<u8> = x"...";

// Create the upgrade proposal data
let upgrade_data = upgrade::new(digest);

// Create and share the proposal (creator's vote is automatically counted)
proposal::new(&quorum_upgrade, upgrade_data, vec_map::empty(), ctx);
```

### Step 3: Voting on a Proposal

Other voters can vote on the proposal:

```move
proposal.vote(&quorum_upgrade, ctx);
```

Voters can also remove their vote if they change their mind:

```move
proposal.remove_vote(&quorum_upgrade, ctx);
```

### Step 4: Executing the Upgrade

Once the quorum is reached, anyone can execute the proposal:

```move
use quorum_upgrade_v2::upgrade;

// Execute the proposal and get the upgrade ticket
let upgrade_ticket = upgrade::execute(proposal, &mut quorum_upgrade);

// Perform the actual upgrade using the ticket
let receipt = package::upgrade(..., upgrade_ticket);

// Commit the upgrade
quorum_upgrade.commit_upgrade(receipt);
```

## Governance Proposals

### Adding a Voter

```move
use quorum_upgrade_v2::add_voter;
use quorum_upgrade_v2::proposal;

// Create proposal to add a new voter
// Optionally update the threshold (e.g., to maintain k out of n ratio)
let add_voter_data = add_voter::new(&quorum_upgrade, new_voter_address, option::some(3));
proposal::new(&quorum_upgrade, add_voter_data, vec_map::empty(), ctx);

// After quorum is reached:
add_voter::execute(proposal, &mut quorum_upgrade);
```

### Removing a Voter

```move
use quorum_upgrade_v2::remove_voter;

let remove_voter_data = remove_voter::new(&quorum_upgrade, voter_to_remove, option::some(2));
proposal::new(&quorum_upgrade, remove_voter_data, vec_map::empty(), ctx);

// After quorum is reached:
remove_voter::execute(proposal, &mut quorum_upgrade);
```

### Replacing a Voter

```move
use quorum_upgrade_v2::replace_voter;

let replace_voter_data = replace_voter::new(&quorum_upgrade, new_voter, old_voter);
proposal::new(&quorum_upgrade, replace_voter_data, vec_map::empty(), ctx);

// After quorum is reached:
replace_voter::execute(proposal, &mut quorum_upgrade);
```

A voter can also replace themselves without a proposal:

```move
quorum_upgrade.replace_self(new_voter_address, ctx);
```

### Updating the Threshold

```move
use quorum_upgrade_v2::update_threshold;

let update_data = update_threshold::new(&quorum_upgrade, new_required_votes);
proposal::new(&quorum_upgrade, update_data, vec_map::empty(), ctx);

// After quorum is reached:
update_threshold::execute(proposal, &mut quorum_upgrade);
```

### Relinquishing the Quorum

To dissolve the quorum and transfer the `UpgradeCap` to a new owner:

```move
use quorum_upgrade_v2::relinquish_quorum;

let relinquish_data = relinquish_quorum::new(new_owner_address);
proposal::new(&quorum_upgrade, relinquish_data, vec_map::empty(), ctx);

// After quorum is reached:
relinquish_quorum::execute(proposal, quorum_upgrade);
```

## Deleting Proposals

The creator of a proposal can delete it:

```move
proposal.delete_by_creator(ctx);
```

## Events

The package emits events to track the lifecycle of proposals and governance changes:

| Event                     | Description                                          |
| ------------------------- | ---------------------------------------------------- |
| `VoteCastEvent`           | Emitted when a voter casts a vote                    |
| `VoteRemovedEvent`        | Emitted when a voter removes their vote              |
| `QuorumReachedEvent`      | Emitted when a proposal reaches the required votes   |
| `ProposalExecutedEvent`   | Emitted when a proposal is executed                  |
| `ProposalDeletedEvent`    | Emitted when a proposal is deleted                   |
| `VoterAddedEvent`         | Emitted when a new voter is added                    |
| `VoterRemovedEvent`       | Emitted when a voter is removed                      |
| `VoterReplacedEvent`      | Emitted when a voter is replaced                     |
| `ThresholdUpdatedEvent`   | Emitted when the required votes threshold is changed |
| `QuorumRelinquishedEvent` | Emitted when the quorum is dissolved                 |

## Security Considerations

### Validation

- Only registered voters can create proposals and vote
- Proposals are validated against the correct `QuorumUpgrade` object
- Vote counts only include addresses that are currently in the voters set
- Threshold updates are validated to ensure they don't exceed the number of voters

### Vote Counting

When checking if quorum is reached, the system only counts votes from addresses that are **currently** in the voters set. This means:

- If a voter is removed after voting, their vote no longer counts
- If a voter is added after a proposal is created, they can still vote on existing proposals

### Self-Replacement

Any voter can replace themselves with a new address using `replace_self()`. This is useful for:

- Key rotation
- Transferring voting rights to a new controlled address

This action does not require a proposal vote, but the voter must sign the transaction.

---

## Appendix: Migrating from V1 to V2

If you are currently using the original Quorum Upgrade Policy (V1) and want to migrate to V2, you can do so by following these steps:

1. **Retrieve the UpgradeCap from V1**: Use the `quorum_upgrade_policy::authorize_upgrade_and_cleanup` function in V1 to extract the `UpgradeCap` from the existing `QuorumUpgradeCap`. This requires a successful vote on a proposed upgrade (which can be a no-op upgrade if you just want to migrate).

   Alternatively, if V1 supports a `destroy` or similar function, use that to unwrap and retrieve the `UpgradeCap`.

2. **Create a new QuorumUpgrade in V2**: Once you have the `UpgradeCap` back, call `quorum_upgrade_v2::quorum_upgrade::new()` with your desired voter set and threshold to create a new V2 quorum.

3. **Communicate with voters**: Ensure all voters are aware of the migration and have the new `QuorumUpgrade` object ID for future proposals.

> 💡 **Note**: The migration requires coordination among the existing V1 voters since extracting the `UpgradeCap` from V1 requires reaching quorum on a proposal. Plan the migration carefully and ensure all parties are prepared before initiating.

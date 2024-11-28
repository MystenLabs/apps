// Copyright (c), Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// ZkBag is a contract to allow transfering of objects (up to a fixed limit)
/// through zksend. This contract allows for:
/// 1. Claiming in an all-or-nothing fashion from the ephemeral address
/// 2. Allowing the owner to reclaim the contents
/// 3. Keeping costs low using TTO (~10x compared to DOFs).
/// 4. Allows re-assignment to a new address by the owner of the bag (link
/// regeneration)
module zk_bag::zk_bag;

use sui::table::{Self, Table};
use sui::transfer::Receiving;
use sui::vec_set::{Self, VecSet};
use sui::event::{Self};

/// Capping this at 50 items as a limit based on business requirements.
/// WARNING: DO NOT EXCEED THE MAXIMUM INPUTs IN A PTB LIMIT,
/// AS THE CONTRACT WILL BECOME UNUSABLE.
const MAX_ITEMS: u64 = 50;

/// Added way too many items in a single bag.
const ETooManyItems: u64 = 0;
/// Access bag without being the owner or the receiver.
const EUnauthorized: u64 = 1;
/// Use an invalid BagClaim to claim items.
const EUnauthorizedProof: u64 = 2;
/// Wrap up a claim process without emptying the bag.
const EBagNotEmpty: u64 = 3;
/// Attached a claim address that already exists.
const EClaimAddressAlreadyExists: u64 = 5;
/// Added or removed items for a claim address that does not exist.
const EClaimAddressNotExists: u64 = 6;
/// Claims an item that does not exist.
const EItemNotExists: u64 = 7;


/// Event emitted when a new ZkBag is created
public struct BagCreatedEvent has copy, drop {
    bag_id: ID,
    creator: address,
}

/// Event emitted when an item of type T is added to a ZkBag
public struct BagItemAddedEvent<phantom T> has copy, drop {
    bag_id: ID,
    creator: address,
}

/// Event emitted when an item of type T is claimed from a ZkBag
public struct BagItemClaimedEvent<phantom T> has copy, drop {
    bag_id: ID,
    creator: address,
    receiver: address,
}

/// Event emitted when all items in a ZkBag are claimed
public struct BagClaimedEvent has copy, drop {
    bag_id: ID,
    creator: address,
    receiver: address,
}

/// Event emitted when ownership of a ZkBag is transferred to a new address
public struct BagOwnerUpdatedEvent has copy, drop {
    bag_id: ID,
    old_owner: address,
    new_owner: address,
}

/// Event emitted when a ZkBag is destroyed after all items are claimed
public struct BagDestroyedEvent has copy, drop {
    bag_id: ID,
}

/// A store that holds all the bags to prevent needing
/// the objectId in the URL of requests.
///
/// We can keep a unique address -> bag map, considering
/// that addresses are ephemeral. They'll be randomly generated and be used
/// once.
public struct BagStore has key {
    id: UID,
    items: Table<address, ZkBag>,
}

/// A hot-potato to make sure that the bag is emptied in one PTB.
public struct BagClaim {
    bag_id: ID,
}

/// The bag that holds the owner, the receiver, and the items.
public struct ZkBag has key, store {
    id: UID,
    owner: address,
    item_ids: VecSet<address>,
}

#[allow(unused_function)]
fun init(ctx: &mut TxContext) {
    transfer::share_object(BagStore {
        id: object::new(ctx),
        items: table::new(ctx),
    })
}

/// Creates a new bag for a receiver address. Aborts if one already exists.
public fun new(store: &mut BagStore, receiver: address, ctx: &mut TxContext) {
    assert!(!store.items.contains(receiver), EClaimAddressAlreadyExists);

    let zk_bag = ZkBag {
        id: object::new(ctx),
        owner: ctx.sender(),
        item_ids: vec_set::empty(),
    };
    
    event::emit(BagCreatedEvent {
        bag_id: object::id(&zk_bag),
        creator: ctx.sender(),
    });

    store
        .items
        .add(
            receiver,
            zk_bag,
        );
}

/// Adds an item of type `T` to the bag.
/// The owner can add items here even after sharing, but most of the use cases
/// wouldn't involve this flow.
public fun add<T: key + store>(
    store: &mut BagStore,
    receiver: address,
    item: T,
    ctx: &mut TxContext,
) {
    assert!(store.items.contains(receiver), EClaimAddressNotExists);

    let bag = store.items.borrow_mut(receiver);

    assert!(bag.owner == ctx.sender(), EUnauthorized);

    assert!(bag.item_ids.size() < MAX_ITEMS, ETooManyItems);

    // we save the list of IDS so that we can strictly-check that we've removed
    // all items in a single-go.
    bag.item_ids.insert(object::id_address(&item));

    event::emit(BagItemAddedEvent<T> {
        bag_id: object::id(bag),
        creator: ctx.sender(),
    });

    // TTO (Transfer to Object) the item to the bag.
    transfer::public_transfer(item, object::id_address(bag));
}

/// Starts a claim flow as the receiver.
public fun init_claim(
    store: &mut BagStore,
    ctx: &mut TxContext,
): (ZkBag, BagClaim) {
    let receiver = ctx.sender();

    assert!(store.items.contains(receiver), EClaimAddressNotExists);
    let bag = store.items.remove(receiver);

    let claim_proof = BagClaim {
        bag_id: object::id(&bag),
    };

    event::emit(BagClaimedEvent {
        bag_id: object::id(&bag),
        creator: bag.owner,
        receiver: receiver,
    });

    (bag, claim_proof)
}

/// Starts a re-claim flow as the creator of the bag.
public fun reclaim(
    store: &mut BagStore,
    receiver: address,
    ctx: &mut TxContext,
): (ZkBag, BagClaim) {
    assert!(store.items.contains(receiver), EClaimAddressNotExists);
    let bag = store.items.remove(receiver);

    assert!(bag.owner == ctx.sender(), EUnauthorized);

    let claim_proof = BagClaim {
        bag_id: bag.id.to_inner(),
    };

    event::emit(BagClaimedEvent {
        bag_id: bag.id.to_inner(),
        creator: bag.owner,
        receiver: receiver,
    });

    (bag, claim_proof)
}

/// Allows switching the receiver address of the bag.
public fun update_receiver(
    store: &mut BagStore,
    from: address,
    to: address,
    ctx: &mut TxContext,
) {
    assert!(store.items.contains(from), EClaimAddressNotExists);
    assert!(!store.items.contains(to), EClaimAddressAlreadyExists);

    let bag = store.items.remove(from);
    // validate that the sender is the owner of the bag.
    assert!(bag.owner == ctx.sender(), EUnauthorized);
    
    event::emit(BagOwnerUpdatedEvent {
        bag_id: object::id(&bag),
        old_owner: from,
        new_owner: to,
    });

    store.items.add(to, bag);
}

/// Claim an item from the bag.
/// Run N of these in a PTB to claim all items. This works in an all-or-nothing
/// way.
public fun claim<T: key + store>(
    bag: &mut ZkBag,
    claim: &BagClaim,
    receiving: Receiving<T>,
    ctx: &mut TxContext,
): T {
    assert!(bag.is_valid_claim_object(claim), EUnauthorizedProof);

    let item = transfer::public_receive(&mut bag.id, receiving);

    // We only claim items the owner explicitly added here (transfered through
    // `add` of this module).
    // Protects us from reducing the count when the item was never explicitly
    // added, or to prevent claiming
    // "spam" objects.
    assert!(bag.item_ids.contains(&object::id_address(&item)), EItemNotExists);

    bag.item_ids.remove(&object::id_address(&item));

    event::emit(BagItemClaimedEvent<T> {
        bag_id: object::id(bag),
        creator: bag.owner,
        receiver: ctx.sender(),
    });

    item
}

/// finalize this + destroy the bag to get storage rebates.
public fun finalize(bag: ZkBag, claim: BagClaim) {
    assert!(bag.is_valid_claim_object(&claim), EUnauthorizedProof);
    assert!(bag.item_ids.is_empty(), EBagNotEmpty);

    let BagClaim { bag_id: _ } = claim;

    event::emit(BagDestroyedEvent {
        bag_id: object::id(&bag),
    });

    let ZkBag {
        id,
        owner: _,
        item_ids: _,
    } = bag;

    id.delete();
}

/// Validate that a bag can be claimed using this BagClaim object.
fun is_valid_claim_object(bag: &ZkBag, claim: &BagClaim): bool {
    claim.bag_id == bag.id.as_inner()
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx)
}

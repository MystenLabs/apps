// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module mkt::collection_bidding_tests {
    use sui::test_utils;
    use sui::kiosk_test_utils::Asset;

    use mkt::collection_bidding::{Self as bidding};
    use mkt::test_utils as test;

    /// The Marketplace witness.
    public struct MyMarket has drop {}

    #[test]
    fun test_simple_bid() {
        let mut test = test::new();
        let ctx = &mut test.next_tx(@0x1);
        let (mut buyer_kiosk, buyer_cap, _) = test.kiosk(ctx);

        // place bids on an Asset: 100 MIST
        let order_id = bidding::place_bids<Asset, MyMarket>(
            &mut buyer_kiosk,
            buyer_cap.borrow(),
            vector[
                test.mint_sui(300, ctx),
                test.mint_sui(400, ctx)
            ],
            ctx
        );

        // prepare the seller Kiosk
        let ctx = &mut test.next_tx(@0x2);
        let (mut seller_kiosk, seller_cap, asset_id) = test.kiosk(ctx);
        let asset_policy = test.policy<Asset>(ctx);
        let mkt_policy = test.policy<MyMarket>(ctx);

        // take the bid and perform the purchase (400 SUI)
        let (asset_request, mkt_request) = bidding::accept_market_bid(
            &mut buyer_kiosk,
            &mut seller_kiosk,
            seller_cap.borrow(),
            &asset_policy,
            asset_id,
            order_id,
            400,
            false,
            ctx
        );

        asset_policy.confirm_request(asset_request);
        mkt_policy.confirm_request(mkt_request);

        assert!(buyer_kiosk.has_item(asset_id), 0);
        assert!(!seller_kiosk.has_item(asset_id), 1);
        assert!(seller_kiosk.profits_amount() == 400, 2);

        // do it all over again
        let (asset, asset_id) = test.asset(ctx);
        seller_kiosk.place(seller_cap.borrow(), asset);

        // second bid (smaller)
        let (asset_request, mkt_request) = bidding::accept_market_bid(
            &mut buyer_kiosk,
            &mut seller_kiosk,
            seller_cap.borrow(),
            &asset_policy,
            asset_id,
            order_id,
            300,
            false,
            ctx
        );

        asset_policy.confirm_request(asset_request);
        mkt_policy.confirm_request(mkt_request);

        assert!(buyer_kiosk.has_item(asset_id), 3);
        assert!(!seller_kiosk.has_item(asset_id), 4);
        assert!(seller_kiosk.profits_amount() == 700, 5);

        test_utils::destroy(seller_kiosk);
        test_utils::destroy(buyer_kiosk);
        test_utils::destroy(seller_cap);
        test_utils::destroy(buyer_cap);

        test.destroy(asset_policy).destroy(mkt_policy);
    }
}

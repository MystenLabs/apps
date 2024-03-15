// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
/// Tests for the marketplace `marketplace_trading_ext`.
module mkt::fixed_trading_tests {
    use sui::test_utils::destroy;
    use sui::kiosk_test_utils::Asset;

    use mkt::test_utils as test;
    use mkt::fixed_trading as ext;

    const PRICE: u64 = 100_000;

    /// Marketplace type.
    public struct MyMarket has drop {}

    #[test] fun test_list_and_delist() {
        let mut test = test::new();
        let ctx = &mut test.next_tx(@0x1);
        let (mut kiosk, cap, asset_id) = test.kiosk(ctx);

        let _order_id = ext::list<MyMarket, Asset>(&mut kiosk, cap.borrow(), asset_id, PRICE, ctx);

        assert!(ext::is_listed<MyMarket, Asset>(&kiosk, asset_id), 0);
        assert!(ext::price<MyMarket, Asset>(&kiosk, asset_id) == PRICE, 1);

        ext::delist<MyMarket, Asset>(&mut kiosk, cap.borrow(), asset_id, ctx);

        let asset: Asset = kiosk.take(cap.borrow(), asset_id);

        destroy(kiosk);
        destroy(asset);
        destroy(cap);
    }

    #[test] fun test_list_and_purchase() {
        let mut test = test::new();
        let ctx = &mut test.next_tx(@0x1);
        let (mut kiosk, cap, asset_id) = test.kiosk(ctx);

        let order_id = ext::list<MyMarket, Asset>(
            &mut kiosk, cap.borrow(), asset_id, PRICE, ctx
        );

        let coin = test.mint_sui(PRICE, ctx);
        let (item, req, mkt_req) = ext::purchase<MyMarket, Asset>(
            &mut kiosk, asset_id, order_id, coin, ctx
        );

        // Resolve creator's Policy
        let policy = test.policy<Asset>(ctx);
        policy.confirm_request(req);
        test.destroy(policy);

        // Resolve marketplace's Policy
        let policy = test.policy<MyMarket>(ctx);
        policy.confirm_request(mkt_req);
        test.destroy(policy);

        test.destroy(kiosk)
            .destroy(item)
            .destroy(cap);
    }
}

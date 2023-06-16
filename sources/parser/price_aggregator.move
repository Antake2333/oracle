module bucket_oracle::price_aggregator {

    use std::vector;
    use std::option::{Self, Option};
    use sui::math::diff;
    use sui::event;
    use sui::clock::{Self, Clock};

    const TOLERANCE_OF_UPDATE_TIME: u64 = 500_000;
    const TOLERANCE_OF_PRICE_DIFF: u64 = 50;

    const ENotEoughPrices: u64 = 0;
    const ESignificientPriceDiff: u64 = 1;

    struct PriceInfo has drop, copy {
        price: u64,
        timestamp: u64,
    }

    struct PriceVector has drop, copy {
        vec: vector<u64>,
    }

    public fun new(price: u64, timestamp: u64): PriceInfo {
        PriceInfo { price, timestamp }
    }

    public fun extract(price_result: &PriceInfo): (u64, u64) {
        (price_result.price, price_result.timestamp)
    }

    public fun push_price(price_vec: &mut vector<PriceInfo>, price_result: Option<PriceInfo>) {
        if (option::is_some(&price_result)) {
            vector::push_back(price_vec, option::destroy_some(price_result));
        } else {
            option::destroy_none(price_result);
        };
    }

    public fun aggregate_price(clock: &Clock, price_vec: vector<PriceInfo>): u64 {
        let price_outputs = vector<u64>[];
        let current_time = clock::timestamp_ms(clock);
        while (!vector::is_empty(&price_vec)) {
            let price_info = vector::pop_back(&mut price_vec);
            let PriceInfo { price, timestamp } = price_info;
            if (diff(current_time, timestamp) <= TOLERANCE_OF_UPDATE_TIME) {
                vector::push_back(&mut price_outputs, price);
            };
        };
        process_prices(price_outputs)
    }

    fun process_prices(prices: vector<u64>): u64 {
        assert!(vector::length(&prices) >= 1, ENotEoughPrices);
        event::emit(PriceVector { vec: prices });
        let price_0 = *vector::borrow(&prices, 0);
        let price_1 = *vector::borrow(&prices, 1);
        let avg_price = (price_0 + price_1) / 2;
        assert!(diff(price_0, price_1) * TOLERANCE_OF_PRICE_DIFF <= avg_price, ESignificientPriceDiff);
        avg_price
    }
}
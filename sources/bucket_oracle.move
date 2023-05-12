module bucket_oracle::bucket_oracle {
    
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::dynamic_object_field as dof;
    use sui::sui::SUI;
    use sui::clock::Clock;

    use bucket_oracle::single_oracle::{Self, SingleOracle};

    struct AdminCap has key { id: UID }

    struct BucketOracle has key { id: UID }

    struct PriceType<phantom T> has copy, drop, store {}

    fun init(ctx: &mut TxContext) {
        let (oracle, admin_cap) = new_oracle(ctx);
        create_single_oracle<SUI>(&admin_cap, &mut oracle, 6, ctx);
        transfer::transfer(admin_cap, tx_context::sender(ctx));
        transfer::share_object(oracle);
    }

    fun new_oracle(ctx: &mut TxContext): (BucketOracle, AdminCap) {
        (BucketOracle { id: object::new(ctx) }, AdminCap { id: object::new(ctx) })
    }

    public fun create_single_oracle<T>(
        _: &AdminCap,
        bucket_oracle: &mut BucketOracle,
        precision_decimal: u8,
        ctx: &mut TxContext,
    ) {
        dof::add<PriceType<T>, SingleOracle<T>>(
            &mut bucket_oracle.id,
            PriceType<T> {}, 
            single_oracle::new(precision_decimal, ctx),
        );
    }

    public fun get_price<T>(bucket_oracle: &BucketOracle, clock: &Clock): (u64, u64) {
        single_oracle::get_price<T>(get_single_oracle(bucket_oracle), clock)
    }

    public fun get_single_oracle<T>(bucket_oracle: &BucketOracle): &SingleOracle<T> {
        dof::borrow<PriceType<T>, SingleOracle<T>>(&bucket_oracle.id, PriceType<T> {})
    }

    public fun get_single_oracle_mut<T>(bucket_oracle: &mut BucketOracle): &mut SingleOracle<T> {
        dof::borrow_mut<PriceType<T>, SingleOracle<T>>(&mut bucket_oracle.id, PriceType<T> {})
    }

    #[test_only]
    public fun new_for_testing<T>(precision_decimal: u8, ctx: &mut TxContext): (BucketOracle, AdminCap) {
        let (oracle, admin_cap) = new_oracle(ctx);
        create_single_oracle<T>(&admin_cap, &mut oracle, precision_decimal, ctx);
        (oracle, admin_cap)
    }
}
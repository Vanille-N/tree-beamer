#![allow(unused_variables)]

extern "Rust" {
    fn miri_write_to_stdout(bytes: &[u8]);
    fn miri_get_alloc_id(ptr: *const ()) -> u64;
    fn miri_print_borrow_state(alloc_id: u64, show_unnamed: bool);
}

#[test]
fn main() { unsafe {
    pattern_chain();
    pattern_flat();
    pattern_mixed();
} }

unsafe fn pattern_chain() {
    let a = &0u64;
    let alloc_id = miri_get_alloc_id(a as *const u64 as *const ());
    miri_write_to_stdout("\n\n".as_bytes());
    miri_write_to_stdout("[..., a]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow a -> b\n".as_bytes());
    let b = &*a;
    miri_write_to_stdout("[..., a, b]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow b -> c\n".as_bytes());
    let c = &*b;
    miri_write_to_stdout("[..., a, b, c]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow c -> d\n".as_bytes());
    let d = &*c;
    miri_write_to_stdout("[..., a, b, c, d]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

}

unsafe fn pattern_flat() {
    let a = &0u64;
    let alloc_id = miri_get_alloc_id(a as *const u64 as *const ());
    miri_write_to_stdout("\n\n".as_bytes());
    miri_write_to_stdout("[..., a]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow a -> b\n".as_bytes());
    let b = &*a;
    miri_write_to_stdout("[..., a, b]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow a -> c\n".as_bytes());
    let c = &*a;
    miri_write_to_stdout("[..., a, b, c]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow a -> d\n".as_bytes());
    let d = &*a;
    miri_write_to_stdout("[..., a, b, c, d]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

}

unsafe fn pattern_mixed() {
    let a = &0u64;
    let alloc_id = miri_get_alloc_id(a as *const u64 as *const ());
    miri_write_to_stdout("\n\n".as_bytes());
    miri_write_to_stdout("[..., a]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow a -> b\n".as_bytes());
    let b = &*a;
    miri_write_to_stdout("[..., a, b]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow b -> c\n".as_bytes());
    let c = &*b;
    miri_write_to_stdout("[..., a, b, c]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow a -> d\n".as_bytes());
    let d = &*a;
    miri_write_to_stdout("[..., a, b, c, d]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

}

//! This is an example execution of Stacked Borrows, meant to illustrate
//! the loss of information due to the one-dimentional nature of the stack.
//! Three different reborrow patterns are shown, where Stacked Borrows loses
//! track of the relationship between them and only remembers the order that
//! they were created.
//!
//! Tree Borrows however remembers more structure and the three functions
//! will have distinguishable outputs.
#![allow(unused_variables)]

// Miri primitives
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

// The reborrow pattern
// ```
// a
// |-- b
// |   '-- c
// '-- d
// ```
// is represented as `[..., a, b, c, d]`
//
// Ignore the clutter before `a`, notice only that at each step
// `b`, `c`, `d` are successively pushed to the top of the stack.
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

// Tag identifiers have changed compared to `pattern_chain`, but
// the structure is the same: after `a`, the reborrows `b`, `c`, `d`
// are pushed on top in that order.
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

// Same thing again with different tags.
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

//! Showing that the tree replicates the structure of reborrows.
//! Pattern has no particular meaning.

// Miri primitives.
extern "Rust" {
    fn miri_write_to_stdout(bytes: &[u8]);
    fn miri_get_alloc_id(ptr: *const ()) -> u64;
    fn miri_print_borrow_state(alloc_id: u64, show_unnamed: bool);
    fn miri_pointer_name(ptr: *const (), nth_parent: u8, name: &[u8]);
}

#[test]
fn main() { unsafe {
    let x = &mut 0u64;
    let alloc_id = miri_get_alloc_id(x as *mut u64 as *const ());
    miri_pointer_name(x as *mut u64 as *const (), 0, "x".as_bytes());

    let y1 = &mut *x;
    miri_pointer_name(y1 as *mut u64 as *const (), 0, "y1".as_bytes());
    let y2 = &*y1;
    miri_pointer_name(y2 as *const u64 as *const (), 0, "y2".as_bytes());

    let z1 = &*x;
    miri_pointer_name(z1 as *const u64 as *const (), 0, "z1".as_bytes());
    let z2 = z1 as *const u64;
    miri_pointer_name(z2 as *const u64 as *const (), 0, "z2".as_bytes());

    foo(x);
    unsafe fn foo(w2: &mut u64) {
        miri_pointer_name(w2 as *mut u64 as *const (), 1, "w1".as_bytes());
        miri_pointer_name(w2 as *mut u64 as *const (), 0, "w2".as_bytes());
        let w3 = &*w2;
        miri_pointer_name(w3 as *const u64 as *const (), 0, "w3".as_bytes());
    }

    miri_write_to_stdout("Ignore the permissions, look only at the structure\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);
} }

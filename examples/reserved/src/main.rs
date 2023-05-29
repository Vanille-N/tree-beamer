//! Demonstration of how Tree Borrows' `Reserved` handles two-phase borrows.
//! Printed lines explain the behavior.

// Miri primitives.
extern "Rust" {
    fn miri_write_to_stdout(bytes: &[u8]);
    fn miri_get_alloc_id(ptr: *const ()) -> u64;
    fn miri_print_borrow_state(alloc_id: u64, show_unnamed: bool);
}

#[test]
fn main() { unsafe {
    let mut v = vec![1usize];
    v.reserve(1); // Ensure that the vector does not get reallocated after we get its `alloc_id`.
    let alloc_id = miri_get_alloc_id(&v as *const Vec<_> as *const ());
    miri_write_to_stdout("There's a lot of clutter, but here's what you should look for:\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);
    miri_write_to_stdout("(0) This is the baseline. Ignore everything visible here in what follows.\n".as_bytes());

    v.push(
        {
            miri_print_borrow_state(alloc_id, true);
            miri_write_to_stdout("(1) Two-phase borrow has started. Look for a tag that was not present in (0) and that has some 'Res' meaning 'Reserved'. Call this tag tg(vpush).\n".as_bytes());

            let n = v.len();

            miri_print_borrow_state(alloc_id, true);
            miri_write_to_stdout("(2) At least one new tag should have been created, as a sibling of tg(vpush). It should be 'Frz' meaning 'Frozen'. Call this tag tg(vlen). Notice that tg(vpush) is still 'Res'.\n".as_bytes());

            n
        }
    );

    miri_print_borrow_state(alloc_id, true);
    miri_write_to_stdout("(3) A write through tg(vpush) has been performed: tg(vpush) is now 'Act' meaning 'Active'. Several children of tg(vpush) should have also been created as side-effects. The access was also a foreign write for tg(vlen) which is now 'Dis' meaning 'Disabled'".as_bytes());
} }

use std::ptr::addr_of_mut;

extern "Rust" {
    fn miri_write_to_stdout(bytes: &[u8]);
    fn miri_get_alloc_id(ptr: *const ()) -> u64;
    fn miri_print_borrow_state(alloc_id: u64, show_unnamed: bool);
}

#[test]
fn main() { unsafe {
    let x = &mut 0u64;
    let alloc_id = miri_get_alloc_id(x as *mut u64 as *const ());
    miri_write_to_stdout("\n".as_bytes());

    miri_write_to_stdout("[..., x]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);
    miri_write_to_stdout("reborrow x -> y\n".as_bytes());
    let y = &mut *addr_of_mut!(*x); // laundering lifetime
    miri_write_to_stdout("[..., x, y]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("reborrow x -> z\n".as_bytes());
    let z = &mut *addr_of_mut!(*x); // laundering lifetime
    miri_write_to_stdout("[..., x, z]\n".as_bytes());
    miri_print_borrow_state(alloc_id, true);

    miri_write_to_stdout("write y\n".as_bytes());
    *y = 42;

    miri_write_to_stdout("write y\n".as_bytes());
    *z = 57;

} }

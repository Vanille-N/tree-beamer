//! Shortcoming of Stacked Borrows: inability to reorder read-only operations.
//! Swap lines (1) and (2) and observe that
//! - under TB, both (1)+(2) and (2)+(1) are allowed
//! - under SB, (1)+(2) is allowed but (2)+(1) is UB, effectively making this reordering unsound
use core::ptr::addr_of_mut;

#[test]
pub fn main() {
    let z = &mut 0;
    let x = unsafe { &mut *addr_of_mut!(*z) };
    *x = 42;

    let _v = *z; // (2)
    let _v = *x; // (1)
}


//! Example found in the wild in crate `imbl`
//! (Issue #59 https://github.com/jneem/imbl/issues/59)
//!
//! Known limitation of Stacked Borrows: UB.
//! Tree Borrows on the other hand accepts this pattern.

#[test]
fn main() {
    let mut foo = imbl::vector![1, 2];
    foo.focus_mut().pair(0, 1, |_, _| {});
}

mod mwe {
    use std::ops::IndexMut;

    #[test]
    fn main() {
        let mut vec = vec![0, 1];
        let slice = vec.as_mut_slice();
        let a: *mut i32 = slice.index_mut(0);
        let b: *mut i32 = slice.index_mut(1);
        unsafe {
            std::mem::swap(&mut *a, &mut *b);
        }
    }
}

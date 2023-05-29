//! This is the flagship example of Tree Borrows, illustrating both at
//! once the purpose of `Reserved` to gracefully handle `as_mut_ptr` and
//! the range-disjointness reasoning.
//!
//! The same code is UB under Stacked Borrows.

#[test]
pub fn main() {
    let buf: &mut [u8] = &mut[5, 46, 205, 19];
    let buf_shr = buf.as_ptr();
    let buf_mut = unsafe { buf.as_mut_ptr().add(2) };
    unsafe { core::ptr::copy_nonoverlapping(buf_shr, buf_mut, 2); }
}


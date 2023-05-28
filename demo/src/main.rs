//! Code pattern demonstrating the
//! interference between raw pointers
//! and assumptions on mutable references.
//! Used as a motivation for introducing
//! Pointer Aliasing Undefined Behavior
//! in Rust, through Stacked or Tree
//! Borrows.





#[allow(unused_variables)]
fn foo(x: &mut u64) {
    // This read is unused after the
    // redundant operation is removed
    let val = *x;


    // We don't know what this does,
    // but we do know that it can't
    // have access to our exclusively
    // owned `x`.
    untrusted::opaque();

    // This write is redundant because
    // `untrusted::opaque` can't modify
    // `*x`
    *x = val;

    // After these optimizations, it is
    // clear that `foo` only calls
    // `untrusted::opaque` and does not
    // change the contents of `x`.
}






fn main() {
    // No matter how shady `untrusted::init`
    // is, we own an `&mut` and now have
    // guaranteed exclusive ownership from
    // type-level information.
    let x: &mut u64 = untrusted::init();

    // Since `foo` does not modify `x`,
    // we should get the same value after
    // than before... right ?
    *x = 42;
    foo(&mut *x);
    assert_eq!(*x, 42); // Oh no.

    // `unsafe` code can thus break the
    // guarantees of the type system, and
    // in doing so invalidate assumptions
    // that can be made in safe contexts.
}


/// The source of our troubles
mod untrusted {
    static mut DATA: u64 = 0;

    pub fn init() -> &'static mut u64 {
        // `unsafe` lets us bypass
        // the type system.
        unsafe { &mut DATA }
    }

    pub fn opaque() {
        // `unsafe` lets us bypass
        // the type system.
        unsafe { DATA = 57; }
    }
}

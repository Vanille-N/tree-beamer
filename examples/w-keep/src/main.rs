//! Limitation of Tree Borrows: cannot assume absence of foreign reads
//! for local variables, which prevents some write-read reorderings.
//! - under TB,
//!   * `MODE = Rw::Read` will not be UB;
//!   * `MODE = Rw::Write` will be UB;
//!   * `MODE = Rw::Nothing` will not be UB;
//!   overall UB is not enough to assume the absence of reads
//! - under SB,
//!   * `MODE = Rw::Read` will be UB;
//!   * `MODE = Rw::Write` will be UB;
//!   * `MODE = Rw::Nothing` will not be UB;
//!   there is sufficient UB to assume the complete absence of accesses
//!   and the optimization that follows

#[test]
pub fn main() {
    let x: &mut u64 = untrusted::init();
    *x = 42;
    untrusted::opaque();
    let _v = *x;
}

#[allow(dead_code)]
mod untrusted {
    enum Rw { Read, Write, Nothing }
    // Parametrize the test by modifying this const
    const MODE: Rw = Rw::Read;

    static mut X: u64 = 0;

    pub fn init() -> &'static mut u64 {
        unsafe { &mut X }
    }

    // Depending on `MODE`, this function may perform
    // one or none of a foreign read or a foreign write,
    // relative to any data handed by `init`.
    pub fn opaque() { unsafe {
        match MODE {
            Rw::Nothing => (),
            Rw::Read => { let _val = X; },
            Rw::Write => { X = 57; },
        }
    } }
}





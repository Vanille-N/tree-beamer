//! Tree Borrows can justify delaying writes for protected references.
//! - under TB,
//!   * `MODE = Rw::Read` will be UB;
//!   * `MODE = Rw::Write` will be UB;
//!   * `MODE = Rw::Nothing` will be UB;
//!   there is sufficient UB to assume the absence of any access.
//!
//! Same reasoning will apply to SB.

#[test]
pub fn main() {
    let x: &mut u64 = untrusted::init();
    let y: &mut u64 = untrusted::other();
    *x = 42;
    *y = 19;
    *x = 57;
    let _v = *x;
}

#[allow(dead_code)]
mod untrusted {
    enum Alias { Bad, No }
    // Parametrize the test by modifying this const
    const MODE: Alias = Alias::Bad;

    static mut X: u64 = 0;
    static mut Y: u64 = 1;

    pub fn init() -> &'static mut u64 {
        unsafe { &mut X }
    }

    // Depending on MODE, the returned reference
    // may or may not be foreign for the one returned by
    // `init`.
    pub fn other() -> &'static mut u64 {
        match MODE {
            Alias::Bad => unsafe { &mut X },
            Alias::No => unsafe { &mut Y },
        }
    }
}





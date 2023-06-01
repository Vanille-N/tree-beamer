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
    *x = 42;
    untrusted::opaque();
    *x = 57;
    let _v = *x;
}

#[allow(dead_code)]
mod untrusted {
    enum Rw { Read, Write, Nothing }
    // Parametrize the test by modifying this const
    const MODE: Rw = Rw::Write;

    static mut X: u64 = 0;

    pub fn init() -> &'static mut u64 {
        unsafe { &mut X }
    }

    // Depending on `MODE`, this function may perform
    // one or none of a foreign read or a foreign write relative
    // to any data handed by `init`.
    pub fn opaque() { unsafe {
        match MODE {
            Rw::Nothing => (),
            Rw::Read => { let _val = X; },
            Rw::Write => { X = 31; },
        }
    } }
}





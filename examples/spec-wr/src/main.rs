//! Limitation of Tree Borrows: cannot justify speculative writes.
//! Having `MODE = Term::Terminate` will properly trigger UB on the next
//! write, however `MODE = Term::Loop` will make future accesses unreachable
//! and unable to trigger UB.
//! Stacked Borrows would trigger UB immediately.

#[test]
pub fn main() {
    let x: &mut u64 = untrusted::init();
    write(&mut *x);
}

fn write(x: &mut u64) {
    untrusted::opaque();
    *x = 42;
}

#[allow(dead_code)]
mod untrusted {
    enum Term { Terminate, Loop }
    // Parametrize the test by modifying this const
    const MODE: Term = Term::Loop;

    static mut X: u64 = 0;

    pub fn init() -> &'static mut u64 {
        unsafe { &mut X }
    }

    // Performs a foreign read for whoever got their data from `init`.
    // May not terminate, making future accesses unreachable.
    pub fn opaque() { unsafe {
        let _val = X;
        match MODE {
            Term::Terminate => (),
            Term::Loop => loop {},
        }
    } }
}





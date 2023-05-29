//! Shows that protectors add the guarantees required by `noalias`:
//! properly detects a conflict `[P]Active -[foreign read]-> [P]Frozen (UB)`

#[test]
fn main() {
    let x: &mut u64 = untrusted::init();
    write(&mut *x);
}

// Write access followed by foreign read is UB.
// This would be a violation of `noalias` otherwise.
fn write(x: &mut u64) {
    *x = 42;
    untrusted::opaque();
}

mod untrusted {
    static mut X: u64 = 0;

    pub fn init() -> &'static mut u64 {
        unsafe { &mut X }
    }

    // Foreign read for whoever receives data from `init`
    pub fn opaque() {
        unsafe { let _val = X; }
    }
}





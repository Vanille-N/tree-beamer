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

    pub fn opaque() { unsafe {
        match MODE {
            Rw::Nothing => (),
            Rw::Read => { let _val = X; },
            Rw::Write => { X = 57; },
        }
    } }
}





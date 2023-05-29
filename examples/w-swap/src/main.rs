#[test]
pub fn main() {
    let x: &mut u64 = untrusted::init();
    write(&mut *x);
}

fn write(x: &mut u64) {
    *x = 42;
    untrusted::opaque();
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

    pub fn opaque() { unsafe {
        match MODE {
            Rw::Nothing => (),
            Rw::Read => { let _val = X; },
            Rw::Write => { X = 57; },
        }
    } }
}





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

    pub fn opaque() { unsafe {
        let _val = X;
        match MODE {
            Term::Terminate => (),
            Term::Loop => loop {},
        }
    } }
}





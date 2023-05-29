#[test]
pub fn main() {
    let x: &u64 = untrusted::init();
    read(&*x);
}

fn read(x: &u64) -> u64 {
    untrusted::opaque();
    *x
}

#[allow(dead_code)]
mod untrusted {
    enum Term { Terminate, Loop }
    // Parametrize the test by modifying this const
    const MODE: Term = Term::Loop;

    static mut X: u64 = 0;

    pub fn init() -> &'static u64 {
        unsafe { &X }
    }

    pub fn opaque() { unsafe {
        X = 57;
        match MODE {
            Term::Terminate => (),
            Term::Loop => loop {},
        }
    } }
}





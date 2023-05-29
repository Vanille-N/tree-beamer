#[test]
fn main() {
    let x: &mut u64 = untrusted::init();
    write(&mut *x);
}

fn write(x: &mut u64) {
    *x = 42;
    untrusted::opaque();
}

mod untrusted {
    static mut X: u64 = 0;

    pub fn init() -> &'static mut u64 {
        unsafe { &mut X }
    }

    pub fn opaque() {
        unsafe { let _val = X; }
    }
}





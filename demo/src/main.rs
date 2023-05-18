static mut PTR: Option<*mut u64> = None;

fn opaque() { unsafe {
    if let Some(ptr) = PTR {
        *ptr += 1;
    }
} }

fn main() {
    let x = &mut 42u64;
    let y = &mut 666u64;
    unsafe { PTR = Some(y as *mut u64); }
    assign(&mut *x, &*y);
    assert_eq!(*x, 666);
}

fn assign(target: &mut u64, source: &u64) {
    let val = *source;
    opaque();
    *target = val;
}

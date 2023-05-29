use core::ptr::addr_of_mut;

#[test]
pub fn main() {
    let z = &mut 0;
    let x = unsafe { &mut *addr_of_mut!(*z) };
    *x = 42;

    let _v = *z;
    let _v = *x;
}


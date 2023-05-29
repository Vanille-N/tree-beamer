#[test]
pub fn main() {
    let buf: &mut [u8] = &mut[5, 46, 205, 19];
    let buf_shr = buf.as_ptr();
    let buf_mut = unsafe { buf.as_mut_ptr().add(2) };
    unsafe { core::ptr::copy_nonoverlapping(buf_shr, buf_mut, 2); }
}


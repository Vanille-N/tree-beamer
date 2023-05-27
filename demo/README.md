# Demo: violation of the exclusive access of a mutable reference


## What is this code ?

This crate purposefully exhibits behavior considered Undefined
by Stacked and Tree Borrows, in an effort to demonstrate the
nontrivial interactions between references and raw pointers.

It is likely and expected that sanitizers will flag part or
all of the code in this example as bad practices, and that
static analysis tools will report possible bugs and undefined
behavior. Ensure that any errors are not intentional before
reporting them.


## Understanding the example

The code itself guides the interpretation of this example,
but here is a brief summary.

```rs
fn foo(x: &mut u64) {
    let val = *x;
    opaque();
    *x = val;
}

fn main() {
    let x = 0u64;
    escape(&mut x);
    foo(&mut x);
}

fn escape(x: &mut u64) {
    // Creates a raw copy of `x`.
    // Implementation details irrelevant.
}

fn opaque() {
    // Unsafely mutates the raw copy of `x`.
    // Implementation details irrelevant.
}
```

The key pattern here is that `escape` makes a raw pointer to `x` available
that will be accessed during `opaque`. This access through a raw pointer
conflicts with the existence and usage of a mutable reference, and triggers
Undefined Behavior.

Assertions are added to the code to exhibit changes in behavior
tied to the presence of Undefined Behavior.


## Running the example

The runner `demo.sh` and the source code `src/main.rs` are intended to
be used together to illustrate
1. when running the code (`$ ./demo.sh run`), behavior is as expected and tests pass.
2. assumptions tied to mutable references can be made to optimize the implementation
   of `foo`, however running the code again (`$ ./demo.sh run`) exhibits
   a change in behavior and tests now fail.
3. The apparent discrepancy between the optimizations performed being both
   a. assumed logically to preserve behavior, and
   b. observed in practice to modify behavior
   is resolved by observing the presence of undefined behavior as reported
   by both Stacked Borrows (`$ ./demo.sh sb`) and Tree Borrows (`$ ./demo.sh tb`)

Follow instructions in comments of `src/main.rs` for details.

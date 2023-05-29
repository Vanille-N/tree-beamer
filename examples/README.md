# Examples

This folder contains executable examples from the presentation.
Use the runner `demo.sh` to execute them:

```sh
# Within the project subfolder, e.g. rw-elim/

$ ../demo.sh test
# Executes `cargo test`

$ ../demo.sh tb
# Executes `MIRIFLAGS=-Zmiri-tree-borrows cargo +miri miri test`

$ ../demo.sh sb
# Executes `MIRIFLAGS= cargo +miri miri test`

# Note:
# Both sb and tb also set MIRIFLAGS+='-Zmiri-tag-gc=0' to guarantee reproducibility,
# but that is more of an implementation detail and relevant only if you care about
# seeing the entire structure.
# If you run miri on your own codebase that contains nontrivial examples,
# DO NOT use -Zmiri-tag-gc=0, performance will suffer a lot.
```

## Index

|Example             |folder      |interesting behavior                                                            |
|--------------------|------------|--------------------------------------------------------------------------------|
|Intro (motivating)  |`rw-elim/`  | `test` succeeds, optimizations make `test` fail, both `tb` and `sb` report UB  |
|Intro (SB demo)     |`sb-weave/` | `sb` shows the stacks and reports UB                                           |
|Intro (info loss)   |`loss/`     | `sb` shows the stacks and they are all isomorphic, `tb` distinguishes them     |
|Structure (demo)    |`structure/`| `tb` replicates the hierarchy of the reborrows                                 |
|Reserved (fixed)    |`reserved/` | `tb` shows `Reserved -[foreign read]-> Reserved -[child write]-> Active`       |
|Protector (fixed)   |`noalias/`  | `tb` reports UB between a read access and a protected `Active`                 |
|Reorder Write-Any   |`w-swap/`   | `tb` reports UB iff `opaque` reads or writes                                   |
|Speculative Read    |`spec-rd/`  | `tb` reports UB immediately, even when the read access is unreachable          |
|Speculative Write   |`spec-wr/`  | `tb` loops without UB, whereas `sb` flags UB even when the write is unreachable|
|`as_mut_ptr` pattern|`mutptr/`   | `tb` allows it, `sb` reports UB                                                |
|Reorder Write-Read  |`w-keep/`   | `tb` only reports UB if a Write is performed, `sb` always reports UB           |
|Reorder Read-Read   |`r-swap/`   | `tb` allows it the reordered version, `sb` reports UB                          |

See further documentation inside the `main.rs` of each example. Some additional details and reasonings
are shown in the corresponding slides.

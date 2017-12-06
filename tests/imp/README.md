IMP and ERC20-K Tests in IMP
============================

This folder includes a semantics of a variant of IMP extended with support
for ERC20-K, as well as dozens of unit tests in IMP for ERC20-K.
The IMP language definition is in
* [imp.k](imp.k)

Each test is an IMP program stored in a file with extension `imp`, and its
expected output is in a corresponding file with extension `.imp.out`.
For example:
* [transfer_Other-AllowanceIrrelevant.imp](transfer_Other-AllowanceIrrelevant.imp)
* [transfer_Other-AllowanceIrrelevant.imp.out](transfer_Other-AllowanceIrrelevant.imp.out)

Each test starts with a statement `test.preamble();`, which initializes
the ERC20-K with a particular configuration holding 10 accounts with balances
10, 20, ..., 100, respectively, and the current caller `7`.
See [imp.k](imp.k) for the precise definition.
Then the test performs one or more ERC20-K transactions using primitives
suffixed with `test.`, such as `test.transfer`, `test.approve`, etc.
See again [imp.k](imp.k) for the precise definitions of these primitives;
they essentially invoke the corresponding ERC20-K primitives and print some
info.

There is one program in the test suite which is different:
* [interactive.imp](interactive.imp)

This program can be used to play with the ERC20 functions interactively,
as shown in the following video:

[![Executing interactive.imp](https://img.youtube.com/vi/aM-JE99C-fQ/0.jpg)](https://www.youtube.com/watch?v=aM-JE99C-fQ)

This can be useful when you add new tests.

### Kompiling IMP and Executing Tests

Before you can execute tests, you need to compile the `imp.k` definition with
the `kompile` command:
* `kompile imp.k`

Ignore the warning
(K likes us to put the syntax of a language in a separate module).
Then you can run tests with the `krun` command, using the `none` output mode
if you do not want to see the resulting configuration (type `krun --help` for
all options):
* `krun .\transfer_Other-AllowanceIrrelevant.imp -o none`

This command will output:
```
7 is approving allowance 20 for 7
7 is transferring 23 to 4
Balance of 7 is 47
Balance of 4 is 63
Allowance of 7 for 4 is 0
```
Finally, you can use the `ktest` command with the provided `config.xml` to run all the tests:
* `ktest config.xml`

This may take several minutes.

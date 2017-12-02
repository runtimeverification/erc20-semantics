Testing and Extending ERC20-K
=============================

Although the ERC20-K semantics was defined to be executable, it requires
an execution environment where its semantic rules can match and apply.
K allows definitions to extend other definitions, by means of importing
and automatically adapting their syntax, configuration and rules.
In particular, we can easily define almost *any programming language
on top of ERC20-K*.

Once you have a language that incorporates ERC20-K, you can at minimum
execute programs that exercise the ERC20 functions.  (You can also verify
such programs, and thus prove properties about ERC20-K, but we do not
elaborate on that here, yet.)  In particular, you can create test-suites that
thoroughly test the ERC20-K specification and thus the ERC20 standard.
Of course, you can do the same with other token specifications, by
modifying our ERC20-K spec accordingly, or replacing it completely.

##IMP

At the time of this writing (December 2017), we have done the above with
only one programming language, the simplest of them all, IMP, which is also
one of the languages that comes with the K distribution.
To learn IMP's semantics and a bit more K, we recommend [k-distribution/tutorial/1_k/2_imp/lesson_5/imp.k](https://github.com/kframework/k/blob/master/k-distribution/tutorial/1_k/2_imp/lesson_5/imp.k).
IMP is a paradigmatic imperative language, with variable
declarations only at the top, assignments, conditional statement, and
while statements.
For interactivity, we added to our IMP here basic I/O (taken over from
[IMP++](https://github.com/kframework/k/blob/master/k-distribution/tutorial/1_k/4_imp%2B%2B/lesson_8/imp.k)).
You can find our complete definition of IMP extended with ERC20-K, as well as
dozens of unit tests exercising a variety of combinations of transactions,
in the following folder (start with the README):

* [tests/imp](imp)


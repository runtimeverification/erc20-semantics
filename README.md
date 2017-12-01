ERC20-K: Formal Executable Specification of ERC20
=================================================

**Acknowledgments:** Warmest thanks to the K team who defined the 
[KEVM](https://github.com/kframework/evm-semantics) semantics
(see
[technical report](https://www.ideals.illinois.edu/handle/2142/97207), too)
and verified smart contracts for ERC20 compliance.
It is their effort that inevitably led to the quest for a formal specification
of ERC20.

We also thank [IOHK](http://iohk.io) not only for their generous funding
support of both [KEVM](https://github.com/kframework/evm-semantics) and
[IELE](https://github.com/runtimeverification/iele-semantics), but also for
the stimulating technical discussions we had with their research team.
Discussions about IELE and about the planned separation between the settlement
and the computational layers in Cardano, in particular, led to the question of
whether the ERC20 specification can be defined in a more abstract way that
makes it usable in combination with computational layers different from EVM.

## Abstract

The [ERC20 standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md)
is one of the most important standards for the implementation of tokens
within Ethereum smart contracts.
ERC20 provides basic functionality to transfer tokens and to be approved so
they can be spent by another on-chain third party.
Unfortunately, ERC20 leaves several corner cases unspecified, which makes it
less than ideal to use in the formal verification of token implementations.
ERC20-K is a complete formal specification of the ERC20 standard.
Specifically, it is a *formal executable semantics* of a *refinement of the
ERC20 standard*, using the [K framework](http://kframework.org).

ERC20-K clarifies what data (accounts, allowances, etc.) are handled by
the various ERC20 functions and the precise meaning of those functions on such
data.
ERC20-K also clarifies the meaning of *all* the corner cases that the ERC20
standard omits to discuss, such as transfers from yourself to yourself
or transfers that result in arithmetic overflows, following the most natural
implementations that aim at minimizing gas consumption.

Being executable, ERC20-K can also be tested for increased confidence.
Driven by the semantic rules that form ERC20-K, as well as by their side
conditions, we manually but systematically produced and provide a test-suite
consisting of several dozens of tests which we believe cover all the corner
cases.
We encourage you to analyze these tests and use them to test your
implementations.
Please contribute with more tests if you think that we left any interesting
behaviors uncovered.


## Motivation

[KEVM](https://github.com/kframework/evm-semantics) makes it possible to
rigorously verify smart contracts at the Ethereum Virtual Machine (EVM) level
against higher level specifications.
The most requested property to verify so far was *correctness of ERC20 tokens*
written in languages like Solidity or Viper.
But what does "correctness of ERC20 tokens" really mean?
When formal verification is sought, a property (or specification) that the
code must satisfy must be available.
Moreover, such a specification should be unambiguous and capable of
answering all the questions regarding corner-case behaviors.
At our knowledge, there was no such formal specification for ERC20, or
for ERC20 variants, available at the time of this writing.

## Structure

[evm.md](evm.md)

[imp.md](imp.md)

## Testing

[tests](tests)

## Contributing

- more tests

- more languages

- how to run ktest

ERC20-K
=======

Below we describe ERC20-K, our formal specification of a refined variant
of the ERC20 standard token in K.
Since it uses a small fragment of K and since the reader may not know K,
we will also explain K as needed.

Our objective is to define ERC20-K in such a way that it can be imported
by an arbitrary programming language semantics, whose programs can then make
use of the ERC20-K functions.
Our immediate reason for doing so is to test ERC20-K programmatically.
But this design choice can have other advantages, too.
For example, it can be seen as a way to *plug-and-play* ERC20-K support
to your favorite language, provided you have a K semantics for it.

We start by defining a module called `ERC20`:

```{.k}
module ERC20
```

A K definition consists of three major parts, often mixed:
syntactic definitions, configuration definitions, and semantic
rules.

## 1 Syntax

We start by defining the ERC20-K syntax.

### 1.1 Values and Addresses

ERC20-K refers to two major types of data: `Value` and `Address`.
We assume that any implementation provides an additional `Bool`
type, or ways to encode it.
It is not difficult to see that although the ERC20 standard is
presented using specific types for values and
addresses, namely `uint256` and `address`, respectively, its
semantics is rather independent of these.
That is, they can be regarded as *parameters* of the specification.
However, to avoid defining adhoc syntactic categories for these,
we here choose them to be K's built-in unbounded integers; note that the
ERC20-K semantics below is defined in a way that bounds on values will be
imposed and preserved.
K's (unbounded) integers live under the predefined syntactic
category `Int`:

```{.k}
  syntax Value   ::= Int  // can be easily changed
  syntax Address ::= Int  // can be easily changed
```

### 1.2 Main Functions

Below is the syntax of the main ERC20 functions:

```{.k}
  syntax AExp ::= Value | Address
                | "totalSupply" "(" ")"
                | "balanceOf" "(" AExp ")"                       [strict]
                | "allowance" "(" AExp "," AExp ")"              [strict]
  syntax BExp ::= Bool
                | "approve" "(" AExp "," AExp ")"                [strict]
                | "transfer" "(" AExp "," AExp ")"               [strict]
                | "transferFrom" "(" AExp "," AExp "," AExp ")"  [strict]
                | "throw"
```

Since we want ERC20-K to be easily incorporated within
programming languages, a minimal interface needs to be agreed upon.
Above, we assumed that such a language must include two syntactic categories:
`AExp` for arithmetic expressions and `BExp` for Boolean expressions.
Values and addresses are `AExp`s and `Bool` values are `BExp`s.
The constructs above, except for `throw`, correspond to the ERC20 standard
functions.
In K, grammars are defined using the BNF notation, with terminals double-quoted.
Note that a syntax/grammar of a language may be and usually is more permissive
than desired; many languages define static type checkers to reject malformed
programs, but this is not our concern here.
The constant `throw` will be used as result of functions which perform illegal
operations and will get the computation stuck.
Note that all arguments of all functions above are `AExp`, meaning
that, syntactically speaking, arbitrary arithmetic expressions are allowed
as arguments of these functions.
Also, all functions that take arguments have the attribute `strict`,
which in K means that they should first evaluate their arguments.
Their semantic rules below will not apply before their arguments are
fully evaluated to their expected types of values.
Consequently, programming language semantics importing our ERC20-K semantics
will allow their programs to pass arbitrary expressions as arguments to
the ERC20 functions, yet the semantics of those functions will apply only
after their arguments are properly evaluated.

### 1.3 Events

The ERC20 functions are required, at success, to log two types of events:

```{.k}
  syntax Event ::= "Transfer" "(" Address "," Address "," Value ")"
                 | "Approval" "(" Address "," Address "," Value ")"
```

The events are then collected in a log.
The precise syntax of the log is not specified in the ERC20 standard, so
in ERC20-K we take the freedom to choose the syntax
`Events: <event1> <event2> ... <eventn>`:

```{.k}
  syntax EventLog ::= "Events:"
                    | EventLog Event
```

The syntax of the event log is unconstrained (by semantic rules) and
is irrelevant for implementations.
All the above is saying is that implementations of ERC20-K must implement
the notion of an event log, together with an *empty* event log and the
capability to *append* a new event to an existing event log.

## 2 Configuration

Configurations hold the structure and the data on which 
the semantic rules match and apply.
At any given moment during its execution, the state of the defined
system or programming language is an instance of the defined
configuration.
A configuration consists of a set of potentially nested
*semantic cells*, each cell having a name and containing a specific
kind of semantic information.
We use an XML-like notation to say where a cell starts and where it ends.
The configuration declaration also contains an initial value for each cell.
We first show the entire ERC20 configuration and then we discuss it:

```{.k}
  configuration <ERC20>
                  <caller> 0 </caller>
                  <k> $PGM:K </k>
                  <accounts>
                    <account multiplicity="*">
                      <id> 0 </id>
                      <balance> 0 </balance>
                    </account>
                  </accounts>
                  <allowances>
                    <allowance multiplicity="*">
                      <owner> 0 </owner>
                      <spenders>
                        <allow multiplicity="*">
                          <spender> 0 </spender>
                          <amount> 0 </amount>
                        </allow>
                      </spenders>
                    </allowance>
                  </allowances>
                  <log> Events: </log>
                  <supply> 0 </supply>
                </ERC20>
```
The configuration consists or a top-level cell `<ERC20/>`, which
holds 6 other cells.

The `<caller/>` holds the initiator of the transaction, aka the sender
of the message, which is an `Address`; we initialize the configuration
with caller `0`.
It is important to know the caller, because the semantics of the transfer
functions depend on it.

The `<k/>` cell holds the computation to be performed by the caller.
The `$PGM:K` variable is replaced with the input program by the K
tools, that is, with the program that we want to execute or whose semantics
we are interested in.
In this module we define the semantics of the ERC20 functions
when they become the first task of the computation, but each programming
language will define the semantics of its additional constructs similarly,
when they become the first task in the `<k/>` cell.
Instead of "become the first task in the `<k/>` cell" we sometimes say
"it is at the top of the `<k/>` cell".

The `<accounts/>` cell holds all the accounts.
Each account is held in a separate `<account/>` cell and has its own
unique `<id/>` and its own `<balance/>`.
The `multiplicity="*"` tag states that there could be zero, one or more
instances of that cell.

The `<allowances/>` cell holds all the allowances: for each `<owner/>`,
its `<spenders/>` cell holds an allowed `<amount/>` for each `<spender/>`.

The `<log/>` cell holds and `EventLog` term, that is, a sequence of `Event`s.
Newly generated events are appended at the end of the log.

The `<supply/>` cell holds the total token supply.

For the reminder of the semantics, we assume the configuration is already
*correctly* initialized: all the account `<id/>`s are distinct, their
`<balance/>`s are non-negative, and the total `<supply/>` is the sum of all
the balances) and the `<caller/>` is known.
In our simple IMP programming language that we define on top of the ERC20-K
semantics (in the `tests` folder) we define macros that can be used to
initialize the configuration.

## 3 Semantics

ERC20 was originally designed for the EVM, whose integers
(of type `uint256`) are unsigned and have `256` bits, so can go up
to `2^256`.
The exact size of integers is important for arithmetic overflow,
which needs to be rigorously defined in the formal specification.
However, the precise size of integers can be a parameter of the
ERC20-K specification.
This way, the specification can easily be used with various execution
environments, such as [eWASM](https://github.com/ewasm/) or 
[IELE](https://github.com/runtimeverification/iele-semantics), or
with various programming languages
(e.g., [Viper](https://github.com/ethereum/viper) appears to converge
towards integers up to `2^128`).
The syntax declaration and the rule below define an integer
constant `MAXVALUE` and initialize it with the largest integer
on 256 bits (one can set it to "infinity" if one does not care about
overflows or if one's computational infrastructure supports unbounded
integers, like
[IELE](https://github.com/runtimeverification/iele-semantics) does):

```{.k}
  syntax Int ::= "MAXVALUE"  [function]
  rule MAXVALUE => 2 ^Int 256 -Int 1
```

The attribute/tag `function` above states that `MAXVALUE`
is to be reduced, or *rewritten*, with its rule above, instantly
wherever it occurs (rewriting of non-function symbols is constrained
by the context).
The suffix `Int` to arithmetic operations indicates that these are
the K builtin operations on its unbounded integers; you can think
of them as the mathematical rather than the machine integer operations.

### 3.1 totalSupply

We start with the semantics of `totalSupply()`:
```{.k}
  rule <k> totalSupply() => Total ...</k>
       <supply> Total </supply>
```
The rule above involves two cells, `<k/>` and `<supply/>`, and matches
`totalSupply()` as the first task in the `</k>` cell and the contents
of the `<supply/>` cell in the `Total` variable.
In K, variables are usually capitalized; `...` is a special variable,
called a *structural frame*, which matches the rest of a sequence, set,
map, cell, etc.  The arrow `=>` indicates that its left-hand-side term
is rewritten to its right-hand-side term.
In words, the rule says: When requested to compute, `totalSupply()`
rewrites to the `Total` contents of the `<supply/>` cell.
Note that rules only need to mention the cells they need; the rest of
the configuration is inferred automatically and rules do not change it.

### 3.2 balanceOf

We next define the semantics of `balanceOf` in a similar but slightly
more involved way:

```{.k}
  rule <k> balanceOf(Id) => Value ...</k>
       <id> Id </id>
       <balance> Value </balance>
```

Above, `balanceOf(Id)` is matched at the top of the `<k/>` cell.
As a result, variable `Id` is bound to a specific account identifier.
Then we match the `<id/>` cell that contains that precise account identifier.
The `Value` of that account then becomes the result of `balanceOf(Id)`.
Note that the `<id/>` and `<balance/>` cells are *not* at the same level
in the configuration as the `<k/>` cell.
K will automatically infer the missing configuration cells as part of its
*configuration abstraction* mechanism, thus saving us from writing
verbose rules, like the following equivalent rule:

```
  rule <k> balanceOf(Id) => Value ...</k>
       <accounts>...
         <account>
           <id> Id </id>
           <balance> Value </balance>
         </account>
       ...</accounts>
```

### 3.3 allowance

The rule for `allowance(Owner,Spender)` makes even more aggressive use of
configuration abstraction:

```{.k}
  rule <k> allowance(Owner, Spender) => Allowance ...</k>
       <owner> Owner </owner>
       <spender> Spender </spender>
       <amount> Allowance </amount>
```

Above, the given `Owner` is matched in its `<allowance/>` cell, then the
`Spender` is matched inside one of owner's `<allow/>` cells, and then the
spender's allowed `Allowance` is returned as the result of the `allowance`
function call.

### 3.4 approve

The semantics of `approve(Spender, Allowance)` is trickier, because it requires
three changes to the configuration (there are three `=>` arrows):
the function call itself becomes `true` in the `<k/>` cell;
at the same time, the allowance of the `<caller/>`, named `Owner` in the rule,
for the `Spender` changes to the new `Allowance`;
finally, an `Approve` event is logged:

```{.k}
  rule <k> approve(Spender, Allowance) => true ...</k>
       <caller> Owner </caller>
       <owner> Owner </owner>
       <spender> Spender </spender>
       <amount> _ => Allowance </amount>
       <log> Log => Log Approval(Owner, Spender, Allowance) </log>
    requires Allowance >=Int 0
```
Above, `_` is an anonymous/nameless variable; it matches the current
`<amount/>` in order to rewrite it to `Allowance`.
K rules can have side conditions on the matched variables, which are introduced
with the keyword `requires`.
We explicitly required the `Allowance` to be positive, which may
be redundant in some languages whose type system already ensures that the values
are positive.
But here we attempt to be as general and safe as possible.
In K, rules can be regarded as *transactions*: they either apply and modify
the configuration atomically, when all the specified structure is matched and
the side conditions are verified, or they do not apply at all and no change
is made to the configuration.

For completeness, we also include the following rule which throws when the
allowance to approve is negative:

```{.k}
  rule <k> approve(_, Allowance) => throw ...</k>
    requires Allowance <Int 0
```

The negative allowance case is not discussed in the ERC20 standard, because
the `uint256` type guarantees integers to be positive.
We believe that the throwing semantics above is more appropriate than having
`approve` return `false`.

### 3.5 transfer

The `transfer(To, Value)` function distinguishes four cases, depending upon
whether the caller transfers the `Value` to itself or to another account, and
whether the function succeeds or throws.

#### 3.5.1 Case 1: Caller different from receiver; success

Let us discuss the successful cases first.
If the caller transfers to a *different* account and all the side conditions
are satisfied, then the two balances and the log are updated accordingly:

```{.k}
  rule <k> transfer(To, Value) => true ...</k>
       <caller> From </caller>
       <account>
         <id> From </id>
         <balance> BalanceFrom => BalanceFrom -Int Value </balance>
       </account>
       <account>
         <id> To </id>
         <balance> BalanceTo => BalanceTo +Int Value </balance>
       </account>
       <log> Log => Log Transfer(From, To, Value) </log>
    requires To =/=Int From    // sanity check
     andBool Value >=Int 0
     andBool Value <=Int BalanceFrom
     andBool BalanceTo +Int Value <=Int MAXVALUE
```

Above, `From` is the caller (matched in the `<caller/>` cell) and
`BalanceFrom` is its balance (matched in the caller's account `<balance/>`
cell), while `BalanceTo` is the receiver's balance (matched in the `To`'s
`<balance/>` cell).
Since we assume the configuration is correctly initialized, `From` should
always be different from `To` because they are ids of different `<account/>`
cells; nevertheless, we prefer to add a sanity check to catch potential errors
in our semantics or in implementations of it.
The other side conditions require that the transfered value is positive and
no larger than the `BalanceFrom`, and that the resulting `BalanceTo` of the
receiver does not overflow.
The ERC20 standard does not cover overflow, but many implementations throw
when overflow occurs, so we prefer to do the same in our specification
(the throwing rules are given after the successful ones).

#### 3.5.2 Case 2: Caller same as receiver; success

Next we discuss successful transfers from the caller to itself.
A self transfer is useless, so it will likely not happen in practice.
Yet, a complete specification to be used for smart contract verification
must nevertheless consider it.
There are at least three possible behaviors to consider for self transfers:

1. Throw.
2. Ignore.
3. Make the actual transfer and log the event.

The first and second cases are the easiest and cleanest to define
semantically, but they may require more code and an additional runtime check
in implementations, so they may result in more gas consumption.
All ERC20 implementations that we've seen, however, do not special case
self transfers, so they implicitly have the third behavior.
Consequently, we also choose the third behavior in our specification.
However we *do* special case the semantics of self transfers because:

1. Only one of the last two conditions in the `requires` clause above needs
to be checked for self transfers (see the note below); and
2. We believe it is important that developers of ERC20-compliant
implementations be aware of the semantic choice and program verifiers
explicitly consider the case of self transfers.

```{.k}
  rule <k> transfer(From, Value) => true ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
       <log> Log => Log Transfer(From, From, Value) </log>
    requires Value >=Int 0
     andBool Value <=Int BalanceFrom
```

**Note:** implementations of `transfer` which *first* add `Value` to
recipient's account and *then* subtract `Value` from sender's account will
fail to satisfy the rule above, because of the potential overflow.
To favor those implementations we would have to change the second requires
clause of the rule above to `BalanceFrom +Int Value <=Int MAXVALUE`.

#### 3.5.3 Case 3: Caller different from receiver; throw

This is the complement rule of Case 1 (distinct caller and receiver),
which throws when the transfered `Value` is negative or exceeds the
`BalanceFrom`, or when overflow happens at receiver:

```{.k}
  rule <k> transfer(To, Value) => throw ...</k>
       <caller> From </caller>
       <account>
         <id> From </id>
         <balance> BalanceFrom </balance>
       </account>
       <account>
         <id> To </id>
         <balance> BalanceTo </balance>
       </account>
    requires To =/=Int From   // sanity check
     andBool (Value <Int 0
      orBool Value >Int BalanceFrom
      orBool BalanceTo +Int Value >Int MAXVALUE)
```

#### 3.5.4 Case 4: Caller same as receiver; throw

Finally, a transfer from the caller to itself throws when the `Value`
is negative or exceeds the `BalanceFrom`:

```{.k}
// self transfer; again, we assume withdrawal followed by deposit
  rule <k> transfer(From, Value) => throw ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
    requires Value <Int 0
      orBool Value >Int BalanceFrom
```

Note that the rule above is a true special case that the specification has to
explicitly treat, and not a trivial instance of the rule preceding it.
Indeed, we chose to not include the overflow condition.
If we included it, then most implementations of the ERC20 token would be
incorrect, because they could not formally guarantee that transfer to self
throws in case of overflow.
Like in Case 2, they would need to first deposit and then withdraw `Value`,
but in that case the side condition `Value >Int Balance` needs to be
eliminated, because a transfer to self would succeed also in that case.

The four rules above only treat the cases where `transfer` either returns
`true` or otherwise `throw`s.
There is no rule where `transfer` returns `false`.
Nevertheless, implementations of tokens may choose to deviate from
our ERC20-K specification, or to refine it, in ways where returning `false`
may be useful.
For example, a particular token implementation may choose to ignore transfers
from some particular account, say 0, intended to hold the burnt tokens,
and may prefer to do that by having `transfer` return `false` instead of
throwing.
Therefore, to allow future flexibility, it makes to give the functions
`transfer`, `transferFrom` and `approve` semantics which return either
`true` or `throw`, without any specific cases returning `false`.


### 3.6 transferFrom

Like `transfer`, `transferFrom(From, To, Value)` also has four cases.
However, unlike `transfer`, we now need to also check and update the
`Caller`'s `Allowance`.

#### 3.6.1 Case 1: `From` different from `To`; success

When `From` different from `To`, indicated by the fact that they are ids of
different accounts, a successful transfer additionally requires that the
`Allowance` of `From` for the `Caller` is larger than or equal to `Value`:

```{.k}
  rule <k> transferFrom(From, To, Value) => true ...</k>
       <caller> Caller </caller>
       <owner> From </owner>
       <spender> Caller </spender>
       <amount> Allowance => Allowance -Int Value </amount>
       <account>
         <id> From </id>
         <balance> BalanceFrom => BalanceFrom -Int Value </balance>
       </account>
       <account>
         <id> To </id>
         <balance> BalanceTo => BalanceTo +Int Value </balance>
       </account>
       <log> Log => Log Transfer(From, To, Value) </log>
    requires To =/=Int From    // sanity check
     andBool Value >=Int 0
     andBool Value <=Int BalanceFrom
     andBool Value <=Int Allowance   // `transfer` does not check allowance
     andBool BalanceTo +Int Value <=Int MAXVALUE
```

Note that a `Transfer` event has also been logged.

#### 3.6.2 Case 2: `From` same as `To`; success

The case of a self transfer (first two arguments of `transferFrom` in the
rule below are equal, `From`) is similar to that of `transfer`, but the
allowance of the `Caller` also needs to be checked and updated:

```{.k}
  rule <k> transferFrom(From, From, Value) => true ...</k>
       <caller> Caller </caller>
       <owner> From </owner>
       <spender> Caller </spender>
       <amount> Allowance => Allowance -Int Value </amount>
       <id> From </id>
       <balance> BalanceFrom </balance>
       <log> Log => Log Transfer(From, From, Value) </log>
    requires Value >=Int 0
     andBool Value <=Int BalanceFrom
     andBool Value <=Int Allowance   // `transfer` does not check allowance
```

Checking and updating the `Caller`'s allowance may look unnecessary for
transfers from an account to itself, but if we do not do it then
ERC20-compliant implementations would require to treat this case as special
and thus would require more code and computation and thus more gas.
Like for `transfer`, our specification above favors implementations that
first withdraw and then deposit the `Value`.
To favor implementations that first deposit and then withdraw, we would
need to replace the last side condition above with an overflow check.

#### 3.6.3 Case 3: `From` different from `To`; throw

This is simply the complement of Case 1:

```{.k}
  rule <k> transferFrom(From, To, Value) => throw ...</k>
       <caller> Caller </caller>
       <owner> From </owner>
       <spender> Caller </spender>
       <amount> Allowance </amount>
       <account>
         <id> From </id>
         <balance> BalanceFrom </balance>
       </account>
       <account>
         <id> To </id>
         <balance> BalanceTo </balance>
       </account>
    requires To =/=Int From    // sanity check
     andBool (Value <Int 0
      orBool Value >Int BalanceFrom
      orBool Value >Int Allowance
      orBool BalanceTo +Int Value >Int MAXVALUE)
```

#### 3.6.4 Case 4: `From` same as `To`; throw

This is simply the complement of Case 2:

```{.k}
  rule <k> transferFrom(From, From, Value) => throw ...</k>
       <caller> Caller </caller>
       <owner> From </owner>
       <spender> Caller </spender>
       <amount> Allowance </amount>
       <id> From </id>
       <balance> BalanceFrom </balance>
    requires Value <Int 0
      orBool Value >Int BalanceFrom
      orBool Value >Int Allowance   // `transfer` does not check allowance
```

The ERC20-K semantics is now complete, so we can close the module:

```{.k}
endmodule
```

## 4 How To Use ERC20-K

One way to use ERC20-K, illustrated in [tests](tests), is to import it in
other programming language semantics and thus offer ERC20 support to those
languages.
In particular, this can be useful to test the ERC20-K specification
programmatically, as well as for producing tests that can be then used with
implementations of ERC20.

Another way to use ERC20-K is as a standard for ERC20 compliance.
That is, as an answer to *what* needs to be proved about a smart contract
claiming to implement an ERC20 token.
Each of the rules above is one reachability claim that needs to be proved.
Several of them have been proved as part of the
[KEVM](https://github.com/kframework/evm-semantics) project about
Solidity and Viper implementations of ERC20 tokens,
and all of them are planned to be proved for a forthcoming ERC20 token
implementation in [IELE](https://github.com/runtimeverification/iele-semantics/).
Indeed, note that the ERC20-K specification above, unlike the original ERC20
standard, is not bound to the EVM anymore.
Finally, since the programming languages in which the tokens are implemented
may have not been given a semantics in the same style as our [tests/imp](tests/imp)
by importing the ERC20-K configuration, a mapping of ERC20-K configurations
into the target language configuration may need to be separately defined.

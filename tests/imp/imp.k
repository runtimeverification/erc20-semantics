/* Author: Grigore Rosu
   Date: 2 December 2017

   The IMP language defined below is mostly imported from the K Tutorial,
   specifically from its IMP and IMP++ languages:
   https://github.com/kframework/k/blob/master/k-distribution/tutorial/1_k/2_imp/lesson_5/imp.k
   https://github.com/kframework/k/blob/master/k-distribution/tutorial/1_k/4_imp%2B%2B/lesson_8/imp.k

   The goal of this language here is to test the ERC20-K specification.
   It therefore adds language extensions to create, initialize, and modify
   the configuration of ERC20-K.  See inlined comments below, where needed.
   We assume the reader familiar with K and the K tutorial definitions
   of IMP and IMP++. */

requires "../../erc20.k"

module IMP
  import ERC20

  syntax AExp  ::= String | Id
                 | "read" "(" ")"
                 > AExp "*" AExp              [left, strict]
                 > AExp "+" AExp              [left, strict]
                 | "(" AExp ")"               [bracket]
  syntax BExp  ::= AExp "<=" AExp             [seqstrict]
                 | AExp "==" AExp             [seqstrict]
                 | "!" BExp                   [strict]
                 > BExp "&&" BExp             [left, strict(1)]
                 > BExp "||" BExp             [left, strict(1)]
                 | "(" BExp ")"               [bracket]
  syntax Block ::= "{" "}"
                 | "{" Stmt "}"
  syntax Stmt  ::= Block
                 | Id "=" AExp ";"            [strict(2)]
                 | "if" "(" BExp ")"
                   Block "else" Block         [strict(1), prefer]
                 | "if" "(" BExp ")" Block
                 | "while" "(" BExp ")" Block
                 | "int" Ids   // use only at the top of the program
                 | "print" "(" AExp ")"       [strict]
                 | "halt"
                 | Stmt ";"
                 > Stmt Stmt                  [left]
  syntax Ids   ::= List{Id,","}

  syntax Stmt ::= AExp ";"                               [strict]
                | BExp ";"                               [strict]
/* The "make" statements below allow us to programmatically interfere
   with the ERC20-K configuration.  Such statements would not be
   possible/allowed in a normal programming language for smart contracts. */
                | "makeAccount" "(" AExp "," AExp")"     [strict]
                | "makeAllowance" "(" AExp "," AExp ")"  [strict]
                | "makeTotalSupply" "(" AExp ")"         [strict]
                | "makeCaller" "(" AExp ")"              [strict]
                | "makeBalance" "(" AExp ")"             [strict]
                | "makeThrowAsPrintTrue"
                | "makeThrowAsPrintFalse"
                | "makePrintStringsTrue"
                | "makePrintStringsFalse"

/* The IMP configuration embeds the ERC20 configuration *unchanged*.
   It adds several new cells to keep track of IMP program's state, I/O, UI. */
  configuration <IMP>
                  initERC20Cell(Init)  // including the ERC20-K configuration.
                  <state> .Map </state>
                  <input color="magenta" stream="stdin"> .List </input>
                  <output color="Orchid" stream="stdout"> .List </output>
                  <throwAsPrint> false </throwAsPrint> // for print THROW
                  <printStrings> true </printStrings>  // for tests
                </IMP>

  syntax KResult ::= Int | Bool | String

// AExp
  rule <k> X:Id => Rho[X] ...</k> <state> Rho </state>
  rule <k> read() => I ...</k>
       <input> ListItem(I:Int) => .List ...</input>  [read]
  rule I1 * I2 => I1 *Int I2
  rule I1 + I2 => I1 +Int I2
// BExp
  rule I1 <= I2 => I1 <=Int I2
  rule I1 == I2 => I1 ==Int I2
  rule ! T => notBool T
  rule true && B => B
  rule false && _ => false
  rule true || _ => true
  rule false || B => B
// Block
  rule {} => .   [structural]
  rule {S} => S  [structural]
// Stmt
  rule <k> X = I:Int; => . ...</k> <state>... X |-> (_ => I) ...</state>
  rule S1:Stmt S2:Stmt => S1 ~> S2  [structural]
  rule if (true)  S else _ => S
  rule if (false) _ else S => S
  rule if (B) S => if (B) S else {}
  rule while (B) S => if (B) {S while (B) S} else {}  [structural]
// Pgm
  rule <k> int (X,Xs => Xs) ...</k> <state> Rho:Map (.Map => X|->0) </state>
    requires notBool (X in keys(Rho))
  rule int .Ids => .  [structural]

/* We slightly modify the semantics of print to allow a flag "printStrings".
   When the flag is true, all strings are printed and integers are printed
   normally.  When the flag is false, the strings are not printed and the
   integers are printed one per line. */

  rule <k> print(I:Int) => . ...</k> <printStrings> true  </printStrings>
       <output>... .List => ListItem(I) </output>
  rule <k> print(I:Int) => . ...</k> <printStrings> false </printStrings>
       <output>... .List => ListItem(I) ListItem("\n") </output>
  rule <k> print(Str:String) => . ...</k> <printStrings> true  </printStrings> <output>... .List => ListItem(Str) </output>
  rule <k> print(Str:String) => . ...</k> <printStrings> false </printStrings>
  rule <k> halt ~> _ => . </k>

/* We also add the following 3 rules which we do not have in the K Tutorial
   IMP.  The reason we add them is to allow us to put semicolon ";" after
   any syntactic construct, in particular after ERC20-K functions.  */

  rule _:Bool; => .
  rule _:Int; => .
  rule S:Stmt; => S

/* Next we define the special "make" constructs which create and modify the
   ERC20-K state.  One should be careful with these constructs, because any
   mistake can make ERC20-K behave unexpectedly.  Such operations should not
   exist in normal implementations of languages for smart contracts.  */

  rule <k> makeAccount(A,V) => . ...</k>
       <accounts>... .Bag => <account> <id> A </id> <balance> V </balance> </account> ...</accounts>
       <allowances>... .Bag => <ledger> <owner> A </owner> <spenders> .Bag </spenders> </ledger> ...</allowances>
  rule <k> makeAllowance(A,B) => . ...</k> <owner> A </owner>
       <spenders>... .Bag => <allow> <spender> B </spender> <amount> 0 </amount> </allow> ...</spenders>
  rule <k> makeTotalSupply(I) => . ...</k> <supply> _ => I </supply> requires I >=Int 0
  rule <k> makeCaller(I:Int) => . ...</k> <caller> _ => I </caller>
  rule <k> makeBalance(I:Int) => . ...</k> <caller> Owner </caller> <id> Owner </id> <balance> _ => I </balance>
  rule <k> makeThrowAsPrintTrue  => . ...</k> <throwAsPrint> _ => true </throwAsPrint>
  rule <k> makeThrowAsPrintFalse => . ...</k> <throwAsPrint> _ => false </throwAsPrint>
  rule <k> throw => false ...</k> <throwAsPrint> true </throwAsPrint> <output>... .List => ListItem("THROW\n") </output>
  rule <k> makePrintStringsTrue  => . ...</k> <printStrings> _ => true  </printStrings>
  rule <k> makePrintStringsFalse => . ...</k> <printStrings> _ => false </printStrings>

/* The next definitions have nothing to do with the IMP semantics.
   They are macros allowing us to write some IMP programs more compactly.
   Note that the objective of this folder is to test the ERC20-K and not
   to define production languages on top of ERC20-K.  Thus we do not pay
   any attention to the viability of the language itself here, but simply
   focus on creating the testing infrastructure that we need.  That being
   said, I think developing a uniform and modular framework to plug-and-play
   ERC20-K in a language that has a K semantics is a very valuable research
   initiative in itself.  In short, I am not proud of the rest of this module
   but the objective was *not* to define something to be proud of.  :)  */

  syntax Id ::= "accounts"  [token]
              | "x"         [token]
              | "y"         [token]
              | "a"         [token]
              | "b"         [token]
              | "c"         [token]
              | "caller"    [token]
              | "v"         [token]

/* ---PREAMBLE----------
   This preamble creates some initial configuration:
     accounts, allowances, supply, caller.
   Recall that this ERC20 semantics assumes that the total supply, all the
   accounts and all their allowances (including those which are 0), as well
   as the caller given.  Then the code is executed on the caller's behalf. */

  syntax Stmt ::= "test.preamble" "(" ")"  [macro]
  rule test.preamble() =>
int accounts, x, y, a, b, c, caller, v;
accounts = 10;
x = accounts;
while(!(x <= 0)) {
  makeAccount(x, x*10);
  y = accounts;
  while(!(y <= 0)) {
    makeAllowance(x,y);
	y = y + -1;
  }
  x = x + -1;
}
makeTotalSupply(550);
caller = 7;
makeCaller(caller);
makeThrowAsPrintTrue;
// ---END-OF-PREAMBLE---

  syntax Stmt ::= "test.makeBalance" "(" AExp ")"   [macro]
  rule test.makeBalance(Value) =>
    v = Value;
    print("Changing the balance of ");
    print(caller);
    print(" to ");
    print(v);
    print("\n");
    makeBalance(v);
    test.balanceOf(caller);

  syntax Stmt ::= "test.makeCaller" "(" AExp ")"   [macro]
  rule test.makeCaller(Id) =>
    caller = Id;
    print("Changing the caller to ");
    print(caller);
    print("\n");
    makeCaller(caller);

  syntax Stmt ::= "test.makeTotalSupply" "(" AExp ")"   [macro]
  rule test.makeTotalSupply(Value) =>
    v = Value;
    print("Changing the total supply to ");
    print(v);
    print("\n");
    makeTotalSupply(v);

  syntax Stmt ::= "test.totalSupply" "(" ")"   [macro]
  rule test.totalSupply() =>
    print("Total supply is ");
    print(totalSupply());
    print("\n");

  syntax Stmt ::= "test.balanceOf" "(" AExp ")"     [macro]
  rule test.balanceOf(Id) =>
    a = Id;
    print("Balance of ");
    print(a);
    print(" is ");
    print(balanceOf(a));
    print("\n");

  syntax Stmt ::= "test.allowance" "(" AExp "," AExp ")"   [macro]
  rule test.allowance(Owner, Spender) =>
    a = Owner;
    b = Spender;
    print("Allowance of ");
    print(a);
    print(" for ");
    print(b);
    print(" is ");
    print(allowance(a,b));
    print("\n");

  syntax Stmt ::= "test.approve" "(" AExp "," AExp ")"   [macro]
  rule test.approve(Spender, Allowance) =>
    b = Spender;
    v = Allowance;
    print(caller);
    print(" is approving allowance ");
    print(v);
    print(" for ");
    print(b);
    print("\n");
    approve(b, v);

  syntax Stmt ::= "test.transfer" "(" AExp "," AExp ")"  [macro]
  rule test.transfer(To, Value) =>
    b = To;
    v = Value;
    print(caller);
    print(" is transferring ");
    print(v);
    print(" to ");
    print(b);
    print("\n");
    transfer(b,v);
    print("Balance of ");
    print(caller);
    print(" is ");
    print(balanceOf(caller));
    print("\n");
    print("Balance of ");
    print(b);
    print(" is ");
    print(balanceOf(b));
    print("\n");
    print("Allowance of ");
    print(caller);
    print(" for ");
    print(b);
    print(" is ");
    print(allowance(caller,b));
    print("\n");

  syntax Stmt ::= "test.transferFrom" "(" AExp "," AExp "," AExp ")"  [macro]
  rule test.transferFrom(From, To, Value) =>
    a = From;
    b = To;
    v = Value;
    print(caller);
    print(" is transferring ");
    print(v);
    print(" from ");
    print(a);
    print(" to ");
    print(b);
    print("\n");
    transferFrom(a,b,v);
    print("Balance of ");
    print(a);
    print(" is ");
    print(balanceOf(a));
    print("\n");
    print("Balance of ");
    print(b);
    print(" is ");
    print(balanceOf(b));
    print("\n");
    print("Allowance of ");
    print(a);
    print(" for ");
    print(caller);
    print(" is ");
    print(allowance(a,caller));
    print("\n");

endmodule

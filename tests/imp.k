requires "../erc20.k"

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
                | "makeAccount" "(" AExp "," AExp")"     [strict]
                | "makeAllowance" "(" AExp "," AExp ")"  [strict]
                | "makeTotalSupply" "(" AExp ")"         [strict]
                | "makeCaller" "(" AExp ")"              [strict]
                | "makeBalance" "(" AExp ")"             [strict]
                | "makeThrowAsPrintTrue"
                | "makeThrowAsPrintFalse"
                | "makePrintStringsTrue"
                | "makePrintStringsFalse"

  configuration <IMP>
                  initERC20Cell(Init)
                  <state> .Map </state>
                  <in color="magenta" stream="stdin"> .List </in>
                  <out color="Orchid" stream="stdout"> .List </out>
                  <throwAsPrint> false </throwAsPrint>
                  <printStrings> true </printStrings>  // for tests
                </IMP>

  syntax KResult ::= Int | Bool | String

// AExp
  rule <k> X:Id => Rho[X] ...</k> <state> Rho </state>
  rule <k> read() => I ...</k>
       <in> ListItem(I:Int) => .List ...</in>  [read]
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
  rule <k> print(I:Int) => . ...</k> <printStrings> true  </printStrings> <out>... .List => ListItem(I) </out>
  rule <k> print(I:Int) => . ...</k> <printStrings> false </printStrings> <out>... .List => ListItem(I) ListItem("\n") </out>
  rule <k> print(Str:String) => . ...</k> <printStrings> true  </printStrings> <out>... .List => ListItem(Str) </out>
  rule <k> print(Str:String) => . ...</k> <printStrings> false </printStrings>
  rule <k> halt ~> _ => . </k>

  rule _:Bool; => .
  rule _:Int; => .
  rule S:Stmt; => S
  rule <k> makeAccount(A,V) => . ...</k>
       <accounts>... .Bag => <account> <id> A </id> <balance> V </balance> </account> ...</accounts>
       <allowances>... .Bag => <allowance> <owner> A </owner> <spenders> .Bag </spenders> </allowance> ...</allowances> 
  rule <k> makeAllowance(A,B) => . ...</k> <owner> A </owner>
       <spenders>... .Bag => <allow> <spender> B </spender> <amount> 0 </amount> </allow> ...</spenders>
  rule <k> makeTotalSupply(I) => . ...</k> <supply> _ => I </supply> requires I >=Int 0
  rule <k> makeCaller(I:Int) => . ...</k> <caller> _ => I </caller>
  rule <k> makeBalance(I:Int) => . ...</k> <caller> Owner </caller> <id> Owner </id> <balance> _ => I </balance>
  rule <k> makeThrowAsPrintTrue  => . ...</k> <throwAsPrint> _ => true </throwAsPrint>
  rule <k> makeThrowAsPrintFalse => . ...</k> <throwAsPrint> _ => false </throwAsPrint>
  rule <k> throw => false ...</k> <throwAsPrint> true </throwAsPrint> <out>... .List => ListItem("THROW\n") </out>

  rule <k> makePrintStringsTrue  => . ...</k> <printStrings> _ => true  </printStrings>
  rule <k> makePrintStringsFalse => . ...</k> <printStrings> _ => false </printStrings>


// Defining some useful macros

  syntax Id ::= "accounts"  [token]
              | "x"         [token]
              | "y"         [token]
              | "a"         [token]
              | "b"         [token]
              | "c"         [token]
              | "caller"    [token]
              | "v"         [token]

  syntax Stmt ::= "test.preamble" "(" ")"  [macro]
  rule test.preamble() =>
// ---PREAMBLE----------
// This preamble creates some initial configuration:
//   accounts, allowances, supply, caller.
// Recall that this ERC20 semantics assumes that the total supply, all the
// accounts and all their allowances (including those which are 0), as well
// as the caller given.  Then the code is executed on the caller's behalf.
// If this preamble is inadequate for your example, then use makeReset at the
// beginning of your program and then initialize the configuration your way.
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
    makeBalance(v);
    test.balanceOf(caller);

  syntax Stmt ::= "test.makeCaller" "(" AExp ")"   [macro]
  rule test.makeCaller(Id) =>
    caller = Id;
    makeCaller(caller);
    print("Caller has been switched to ");
    print(caller);
    print("\n");

  syntax Stmt ::= "test.makeTotalSupply" "(" AExp ")"   [macro]
  rule test.makeTotalSupply(Value) =>
    v = Value;
    makeTotalSupply(v);
    test.totalSupply();

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
    approve(b, v);
    print("Allowance of ");
    print(caller);
    print(" for ");
    print(b);
    print(" is ");
    print(allowance(caller,b));
    print("\n");

  syntax Stmt ::= "test.transfer" "(" AExp "," AExp ")"  [macro]
  rule test.transfer(To, Value) =>
    b = To;
    v = Value;
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

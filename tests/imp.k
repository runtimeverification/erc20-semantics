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
                 | "print" "(" AExp ")"       [strict]
                 | "halt"
                 | Stmt ";"
                 > Stmt Stmt                  [left]
  syntax Pgm ::= "int" Ids ";" Stmt
  syntax Ids ::= List{Id,","}

  syntax Stmt ::= AExp ";"                  [strict]
                | BExp ";"                  [strict]
                | makeAccount(AExp,AExp)    [strict]
                | makeAllowance(AExp,AExp)  [strict]
                | makeTotalSupply(AExp)     [strict]
                | makeCaller(AExp)          [strict]
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
                  <printStrings> true </printStrings>
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
  rule <k> int (X,Xs => Xs);_ </k> <state> Rho:Map (.Map => X|->0) </state>
    requires notBool (X in keys(Rho))
  rule int .Ids; S => S  [structural]
  rule <k> print(I:Int) => . ...</k> <printStrings> true  </printStrings> <out>... .List => ListItem(I) </out>
  rule <k> print(I:Int) => . ...</k> <printStrings> false </printStrings> <out>... .List => ListItem(I) ListItem("\n") </out>
  rule <k> print(Str:String) => . ...</k> <printStrings> true  </printStrings> <out>... .List => ListItem(Str) </out>
  rule <k> print(Str:String) => . ...</k> <printStrings> false </printStrings>
  rule <k> halt ~> _ => . </k>

  rule _:Bool; => .
  rule _:Int; => .
  rule S:Stmt; => S
  rule <k> makeAccount(A,V) => . ...</k>
       <accounts>... .Bag => <account> <id> A </id> <balance> V </balance>
                             <allowances> .Bag </allowances> </account> ...</accounts>
  rule <k> makeAllowance(A,B) => . ...</k> <id> A </id>
       <allowances>... .Bag => <allowance> <spender> B </spender> <amount> 0 </amount> </allowance> ...</allowances>
  rule <k> makeTotalSupply(I) => . ...</k> <supply> _ => I </supply>
  rule <k> makeCaller(I:Int) => . ...</k> <caller> _ => I </caller>
  rule <k> makeThrowAsPrintTrue  => . ...</k> <throwAsPrint> _ => true </throwAsPrint>
  rule <k> makeThrowAsPrintFalse => . ...</k> <throwAsPrint> _ => false </throwAsPrint>
  rule <k> throw => false ...</k> <throwAsPrint> true </throwAsPrint> <out>... .List => ListItem("THROW\n") </out>

  rule <k> makePrintStringsTrue  => . ...</k> <printStrings> _ => true  </printStrings>
  rule <k> makePrintStringsFalse => . ...</k> <printStrings> _ => false </printStrings>

endmodule

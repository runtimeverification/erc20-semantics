requires "erc20.k"

module IMP
  import ERC20

  syntax AExp  ::= Id
                 | AExp "*" AExp              [left, strict]
                 > AExp "+" AExp              [left, strict]
                 | "(" AExp ")"               [bracket]
  syntax BExp  ::= AExp "<=" AExp             [seqstrict, latex({#1}\leq{#2})]
                 | "!" BExp                   [strict]
                 > BExp "&&" BExp             [left, strict(1)]
                 | "(" BExp ")"               [bracket]
  syntax Block ::= "{" "}"
                 | "{" Stmt "}"
  syntax Stmt  ::= Block
                 | Id "=" AExp ";"            [strict(2)]
                 | "if" "(" BExp ")"
                   Block "else" Block         [strict(1)]
                 | "while" "(" BExp ")" Block
  				 | Stmt ";"
                 > Stmt Stmt                  [left]
  syntax Pgm ::= "int" Ids ";" Stmt
  syntax Ids ::= List{Id,","}

  syntax Stmt ::= AExp ";"                         [strict]
				| BExp ";"                         [strict]
				| makeAccount(AExp,AExp)           [strict]
				| makeAllowanceOwner(AExp)         [strict]
				| makeAllowanceSpender(AExp,AExp)  [strict]
				| makeCaller(AExp)                 [strict]

  configuration <IMP>
                  initERC20Cell(Init)
				  <state> .Map </state>
				</IMP>

  syntax KResult ::= Int | Bool

// AExp
  rule <k> X:Id => I ...</k> <state>... X |-> I ...</state>
  rule I1 * I2 => I1 *Int I2
  rule I1 + I2 => I1 +Int I2
// BExp
  rule I1 <= I2 => I1 <=Int I2
  rule ! T => notBool T
  rule true && B => B
  rule false && _ => false
// Block
  rule {} => .   [structural]
  rule {S} => S  [structural]
// Stmt
  rule <k> X = I:Int; => . ...</k> <state>... X |-> (_ => I) ...</state>
  rule S1:Stmt S2:Stmt => S1 ~> S2  [structural]
  rule if (true)  S else _ => S
  rule if (false) _ else S => S
  rule while (B) S => if (B) {S while (B) S} else {}  [structural]
// Pgm
  rule <k> int (X,Xs => Xs);_ </k> <state> Rho:Map (.Map => X|->0) </state>
    requires notBool (X in keys(Rho))
  rule int .Ids; S => S  [structural]

  rule true; => .
  rule _:Int; => .
  rule S:Stmt; => S
  rule <k> makeAccount(A,V) => . ...</k>
       <accounts>... .Bag => <account> <id> A </id> <balance> V </balance> </account> ...</accounts>
  rule <k> makeAllowanceOwner(A) => . ...</k>
       <allowances>... .Bag => <allowance> <owner> A </owner> <spenders> .Bag </spenders> </allowance> ...</allowances>
  rule <k> makeAllowanceSpender(A,B) => . ...</k>
       <allowance> <owner> A </owner> <spenders>... .Bag => <allow> <spender> B </spender> <amount> 0 </amount> </allow> ...</spenders> </allowance>
  rule <k> makeCaller(I:Int) => . ...</k>
       <caller> _ => I </caller>
endmodule

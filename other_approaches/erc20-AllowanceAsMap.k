//
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//

module ERC20
  syntax Int ::= "MAXVALUE"  [function]
  syntax Address ::= Int  // this can be changed
  syntax AExp ::= Int
                | Address
                | "totalSupply" "(" ")"
                | "balanceOf" "(" AExp ")"                       [strict]
                | "allowance" "(" AExp "," AExp ")"              [strict]
  syntax BExp ::= Bool
                | "approve" "(" AExp "," AExp ")"                [strict]
                | "transfer" "(" AExp "," AExp ")"               [strict]
                | "transferFrom" "(" AExp "," AExp "," AExp ")"  [strict]
                | "throw"
  syntax Event ::= "Transfer" "(" Address "," Address "," Int ")"
                 | "Approval" "(" Address "," Address "," Int ")"
  syntax EventLog ::= "Events:"
                    | EventLog Event

  configuration <ERC20>
                  <caller> 0 </caller>
                  <k> $PGM:K </k>
                  <log> Events: </log>
                  <supply> 0 </supply>
                  <accounts map="">
                    <account multiplicity="*">
                      <id key=""> 0 </id>
                      <balance> 0 </balance>
                      <allowances>
                        .Map
                      </allowances>
                    </account>
                  </accounts>
                </ERC20>

  rule MAXVALUE => 2 ^Int 256 -Int 1

  rule <k> totalSupply() => Total ...</k>
       <supply> Total </supply>

  rule <k> balanceOf(Owner) => Value ...</k>
       <id> Owner </id>
       <balance> Value </balance>

  rule <k> allowance(Owner, Spender) => Allowances[Spender] ...</k>
       <id> Owner </id>
       <allowances> Allowances </allowances>

  rule <k> approve(Spender, Allowance) => true ...</k>
       <caller> Owner </caller>
       <id> Owner </id>
       <allowances> Allowances[Spender <- Allowance] </allowances>
      <log> Log => Log Approval(Owner, Spender, Allowance) </log>

  rule <k> transfer(To, Value) => true ...</k>
       <caller> From </caller>
       <account>...
         <id> From </id>
         <balance> BalanceFrom => BalanceFrom -Int Value </balance>
       ...</account>
       <account>...
         <id> To </id>
         <balance> BalanceTo => BalanceTo +Int Value </balance>
       ...</account>
       <log> Log => Log Transfer(From, To, Value) </log>
    requires To =/=Int From    // sanity check
     andBool Value >=Int 0
     andBool Value <=Int BalanceFrom
     andBool BalanceTo +Int Value <=Int MAXVALUE

  rule <k> transfer(From, Value) => true ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
       <log> Log => Log Transfer(From, From, Value) </log>
    requires Value >=Int 0
     andBool Value <=Int BalanceFrom

  rule <k> transfer(To, Value) => throw ...</k>
       <caller> From </caller>
       <account>...
         <id> From </id>
         <balance> BalanceFrom </balance>
       ...</account>
       <account>...
         <id> To </id>
         <balance> BalanceTo </balance>
       ...</account>
    requires To =/=Int From   // sanity check
     andBool (Value <Int 0
      orBool Value >Int BalanceFrom
      orBool BalanceTo +Int Value >Int MAXVALUE)

// self transfer; again, we assume withdrawal followed by deposit
  rule <k> transfer(From, Value) => throw ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
    requires Value <Int 0
      orBool Value >Int BalanceFrom

  rule <k> transferFrom(From, To, Value) => true ...</k>
       <account>...
         <id> From </id>
         <balance> BalanceFrom => BalanceFrom -Int Value </balance>
         <allowances> Allowances => Allowances[To <- (Allowances[To]:>Int -Int Value)] </allowances>
       ...</account>
       <account>...
         <id> To </id>
         <balance> BalanceTo => BalanceTo +Int Value </balance>
       ...</account>
       <log> Log => Log Transfer(From, To, Value) </log>
    requires To =/=Int From    // sanity check
     andBool Value >=Int 0
     andBool Value <=Int BalanceFrom
     andBool Value <=Int Allowances[To]:>Int
     andBool BalanceTo +Int Value <=Int MAXVALUE

  rule <k> transferFrom(From, To, Value) => throw ...</k>
       <id> From </id>
       <balance> BalanceFrom </balance>
       <allowances> Rho </allowances>
    requires Value <Int 0
      orBool Value >Int BalanceFrom
      orBool Value >Int Rho[To]:>Int

  rule <k> approve(Spender, Allowance) => true ...</k>
       <caller> Owner </caller>
       <id> Owner </id>
       <allowances> Rho[Spender <- Allowance] </allowances>
       <log> Log => Log Approval(Owner, Spender, Allowance) </log>

endmodule

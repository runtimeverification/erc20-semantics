//
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//

module ERC20
  syntax Address ::= Int  // this can be changed
  syntax Value   ::= Int  // this can be changed
  syntax AExp ::= Int
                | Address
                | Value
                | "totalSupply" "(" ")"
                | balanceOf(AExp)
                | allowance(AExp, AExp)
  syntax BExp ::= Bool
                | transfer(AExp, AExp)            [strict]
                | transferFrom(AExp, AExp, AExp)  [strict]
                | approve(AExp, AExp)             [strict]
                | "throw"
  syntax Event ::= Transfer(Address, Address, Int)
                 | Approval(Address, Address, Int)

  configuration <ERC20>
                  <caller> 0 </caller>
                  <k> $PGM:K </k>
                  <log> .List </log>
                  <supply> 0 </supply>
                  <accounts>
                    <account multiplicity="*">
                      <id> 0 </id>
                      <balance> 0 </balance>
                      <allowances>
                        <allowance multiplicity="*">
                          <spender> 0 </spender>
                          <amount> 0 </amount>
                        </allowance>
                      </allowances>
                    </account>
                  </accounts>
                </ERC20>

  rule <k> totalSupply() => Total ...</k>
       <supply> Total </supply>
       
  rule <k> balanceOf(Owner) => Value ...</k>
       <id> Owner </id>
       <balance> Value </balance>

  rule <k> allowance(Owner, Spender) => Allowance ...</k>
       <id> Owner </id>
       <spender> Spender </spender>
       <amount> Allowance </amount>

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
       <log>... .List => ListItem(Transfer(From, To, Value)) </log>
    requires Value >=Int 0
     andBool Value <=Int BalanceFrom

  rule <k> transfer(_, Value) => throw ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
    requires Value <Int 0
      orBool Value >Int BalanceFrom

  rule <k> transferFrom(From, To, Value) => true ...</k>
       <account>...
         <id> From </id>
         <balance> BalanceFrom => BalanceFrom -Int Value </balance>
         <spender> To </spender>
         <amount> Allowance => Allowance -Int Value </amount>
       ...</account>
       <account>...
         <id> To </id>
         <balance> BalanceTo => BalanceTo +Int Value </balance>
       ...</account>
       <log>... .List => ListItem(Transfer(From, To, Value)) </log>
    requires Value >=Int 0
     andBool Value <=Int BalanceFrom
     andBool Value <=Int Allowance

  rule <k> transferFrom(From, To, Value) => throw ...</k>
       <id> From </id>
       <balance> BalanceFrom </balance>
       <spender> To </spender>
       <amount> Allowance </amount>
    requires Value <Int 0
      orBool Value >Int BalanceFrom
      orBool Value >Int Allowance

  rule <k> approve(Spender, Allowance) => true ...</k>
       <caller> Owner </caller>
       <id> Owner </id>
       <spender> Spender </spender>
       <amount> _ => Allowance </amount>
       <log>... .List => ListItem(Approval(Owner, Spender, Allowance)) </log>

endmodule

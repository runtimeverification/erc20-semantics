//
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//

module ERC20
  syntax Address ::= Int  // this can and should be changed
  syntax AExp ::= Int
                | "totalSupply" "(" ")"
                | balanceOf(Address)
                | allowance(Address, Address)
  syntax BExp ::= Bool
                | transfer(Address, AExp)              [strict]
                | transferFrom(Address, Address, AExp) [strict]
                | approve(Address, AExp)               [strict]
                | "throw"
  syntax Event ::= Transfer(Address, Address, Int)
                 | Approval(Address, Address, Int)

  configuration <ERC20>
                  <caller> 0 </caller>
                  <k> $PGM:K </k>
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
                  <log> .List </log>
                  <accounts>
                    <account multiplicity="*">
                      <id> 0 </id>
                      <balance> 0 </balance>
                    </account>
                  </accounts>
                  <supply> 0 </supply>
                </ERC20>

  rule <k> totalSupply() => Total ...</k>
       <supply> Total </supply>
       
  rule <k> balanceOf(Owner) => Value ...</k>
       <id> Owner </id>
       <balance> Value </balance>

  rule <k> allowance(Owner, Spender) => Allowance ...</k>
       <owner> Owner </owner>
       <spender> Spender </spender>
       <amount> Allowance </amount>

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
       <log>... .List => ListItem(Transfer(From, To, Value)) </log>
    requires Value <=Int BalanceFrom

  rule <k> transfer(_, Value) => throw ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
    requires Value >Int BalanceFrom

  rule <k> transferFrom(From, To, Value) => true ...</k>
       <account>
         <id> From </id>
         <balance> BalanceFrom => BalanceFrom -Int Value </balance>
       </account>
       <account>
         <id> To </id>
         <balance> BalanceTo => BalanceTo +Int Value </balance>
       </account>
       <owner> From </owner>
       <spender> To </spender>
       <amount> Allowance => Allowance -Int Value </amount>
       <log>... . => ListItem(Transfer(From, To, Value)) </log>
    requires Value <=Int BalanceFrom
     andBool Value <=Int Allowance

  rule <k> transferFrom(From,To,Value) => throw ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
       <owner> From </owner>
       <spender> To </spender>
       <amount> Allowance </amount>
    requires Value >Int BalanceFrom
       orBool Value >Int Allowance

  rule <k> approve(Spender, Allowance) => true ...</k>
       <caller> Owner </caller>
       <owner> Owner </owner>
       <spender> Spender </spender>
       <amount> Allowance </amount>
       <log>... .List => ListItem(Approval(Owner, Spender, Allowance)) </log>

endmodule

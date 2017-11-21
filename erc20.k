//
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// Get the total token supply
//    function totalSupply() constant returns (uint256 totalSupply)
// Get the account balance of another account with address _owner
//    function balanceOf(address _owner) constant returns (uint256 balance)
// Send _value amount of tokens to address _to
//    function transfer(address _to, uint256 _value) returns (bool success)
// Send _value amount of tokens from address _from to address _to
//    function transferFrom(address _from, address _to, uint256 _value) returns (bool success)
// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
// If this function is called again it overwrites the current allowance with _value.
//    function approve(address _spender, uint256 _value) returns (bool success)
// Returns the amount which _spender is still allowed to withdraw from _owner
//    function allowance(address _owner, address _spender) constant returns (uint256 remaining)

module ERC20
  syntax AExp ::= totalSupply()
                | balanceOf(Int)
                | allowance(Int, Int)
  syntax BExp ::= transfer(Int, Int)
			    | transferFrom(Int, Int, Int)
				| approve(Int, Int)
                | "throw"
  syntax Event ::= Transfer(Int, Int, Int)
                 | Approval(Int, Int, Int)

  configuration   <caller> 0 </caller>
                  <k> $PGM </k>
                  <allowances>
                    <allowance multiplicity="*">
                      <owner> 0 </owner>
                      <allows multiplicity="*">
                        <spender> 0 </spender>
                        <amount> 0 </amount>
                      </allows>
                    </allowance>
                  <allowances>
                  <log> .List </log>
                  <accounts>
                    <account multiplicity="*">
                      <id> 0 </id>
  					  <balance> 0 </balance>
                    </account>
                    <supply> 0 </supply>
                  </accounts>

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

   rule <k> transferFrom(From, To, Value) => true ...<k>
       <account>
         <id> From </id>
         <balance> BalanceFrom => BalanceFrom -Int Value </balance>
       </account>
       <account>
         <id> To </id>
         <balance> BalanceTo => BalanceTo +Int Value </balance>
       </account>
       <owner> From </owner>
       <sender> To </sender>
       <amount> Allowance => Allowance -Int Value </amount>
       <log>... . => ListItem(Transfer(From, To, Value)) </log>
    requires Value <=Int BalanceFrom
     andBool Value <=Int Allowance

  rule <k> transferFrom(From,To,Value) => throw ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
       <owner> From </owner>
       <sender> To </sender>
       <amount> Allowance </amount>
     requires Value >Int BalanceFrom
       orBool Value >Int Allowance

  rule <k> approve(Spender, Allowance) => true ...</k>
       <caller> Owner </caller>
       <owner> Owner </owner>
       <spender> Spender </spender>
       <amount> Allowance </amount>
       <log>... .List => ListItem(Approve(Owner, Spender, Allowance)) </log>

endmodule

module IMP
  syntax KResult ::= Int | Bool
  ...
endmodule


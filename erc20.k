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

  rule MAXVALUE => 2 ^Int 256 -Int 1

  rule <k> totalSupply() => Total ...</k>
       <supply> Total </supply>
       
  rule <k> balanceOf(Id) => Value ...</k>
       <id> Id </id>
       <balance> Value </balance>

  rule <k> allowance(Owner, Spender) => Allowance ...</k>
       <owner> Owner </owner>
       <spender> Spender </spender>
       <amount> Allowance </amount>

  rule <k> approve(Spender, Allowance) => true ...</k>
       <caller> Owner </caller>
       <owner> Owner </owner>
       <spender> Spender </spender>
       <amount> _ => Allowance </amount>
       <log> Log => Log Approval(Owner, Spender, Allowance) </log>
    requires Allowance >=Int 0

  rule <k> approve(_, Allowance) => throw ...</k>
    requires Allowance <Int 0

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

/*
A self transfer is useless, so it will likely not happen in practice.
Yet, a complete specification of ERC20 must nevertheless consider it.
There are at least three possible behaviors to consider for self transfers:
(1) Throw.
(2) Ignore.
(3) Make the actual transfer and log the event.
The first and second cases are the easiest and cleanest to define
semantically, but they may require more code and an additional runtime check
in implementations, so they may result in more gas consumption (assuming the
code is complex enough for compilers to optimize and eliminate the check).
All ERC20 implementations that we've seen, however, do not special case
self transfers, so they implicitly have the third behavior.
Consequently, we also choose the third behavior in our specification.
However we *do* special case the semantics of self transfers because:
(1) Only one of the last two conditions in the `requires` clause above needs
    to be checked for self transfers (see the note below); 
(2) We believe it is important that developers of ERC20 implementations be
    aware of the semantic choice and program verifiers explicitly consider the
    case of self transfers.
Note: implementations of `transfer` which first add `Value` to recipient's
account and then subtract Value from sender's account will fail to satisfy the
rule below, because of the potential overflow.  To favor those implementations
we would have to change the second requires clause of the rule below to
`BalanceFrom +Int Value <=Int MAXVALUE`.
*/ 
  rule <k> transfer(From, Value) => true ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
       <log> Log => Log Transfer(From, From, Value) </log>
    requires Value >=Int 0
     andBool Value <=Int BalanceFrom

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

// self transfer; again, we assume withdrawal followed by deposit
  rule <k> transfer(From, Value) => throw ...</k>
       <caller> From </caller>
       <id> From </id>
       <balance> BalanceFrom </balance>
    requires Value <Int 0
      orBool Value >Int BalanceFrom

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

// self transfer; again, we assume withdrawal followed by deposit
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

// self transfer; again, we assume withdrawal followed by deposit
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

endmodule

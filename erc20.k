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

module ERC20-SYNTAX
  syntax AExp ::= totalSupply()
                | balanceOf(Int)
                | allowance(Int,Int)
  syntax BExp ::= transfer(Int,Int)
			    | transferFrom(Int,Int,Int)
				| approve(Int,Int)
endmodule


module ERC20
  imports ERC20-SYNTAX
  syntax KResult ::= Int | Bool

  configuration   <k> $PGM </k>
                  <accounts>
                    <account multiplicity="*">
                      <id> 0 </id>
  					  <value> 0 </value>
                    </account>
                  </accounts>

endmodule

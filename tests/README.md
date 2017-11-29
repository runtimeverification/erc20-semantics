- Special commands (those with negative index) are assumed to be used correctly
so they are not thoroughly tested.  In particular, makeTotalSupply gets stuck
if the new supply is negative.
- No assumption is made about transfered values or allowances to be
nonnegative.  The semantics checks if they are indeed so and if not it throws.
Many implementations/compilers will likely disallow negative values statically
(for example, if they use the uint256 type for values).  But we keep the check
for safety.
- We assume the initial configuration is correctly constructed.  That is, all
the accounts are created, and each account contains all its allowances,
including an allowance for itself (needed in case of a transferFrom to itself).
- caller is set to 7 in preamble

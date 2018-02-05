ScottE CPU
==========

The ScottE is an 8bit processor based on Scott's CPU in his book
["But How Do It Know"](http://buthowdoitknow.com). It differers from the original in these points:

1. Use of microcode instead of fixed logic as Control Unit.
2. Support for subtraction and hence different ALU flags.
3. Modified instructions: ldr, str, jmp
4. Removed instructions: not, clf, jmpr
5. New instructions: sub, halt, mov

Thus it is neither binary compatible nor semantically compatible with the original CPU.

This processor is designed with the [Logisim](http://www.cburch.com/logisim) software. Read the
documentation on the website or watch videos on Youtube for information concerning the usage of
that tool.

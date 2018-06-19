ScottE v4
=========

Registers
---------

[....|....] R0
[....|....] R1
[....|....] R2
[....|....] R3

[....|....] SP
[....|....] NPC
[....|....] PC
[mhix|vcsz] FR


Flags
-----

z:  zero flag
s:  sign
c:  carry flag
v:  overflow
ix: memory index
h:  halt
m:  manual mode


Address Space
-------------

ScottE v4 can address 1KB of memory. The address space has four 256B regions:
0x000-0x0ff: ROM
0x100-0x1ff: Stack
0x200-0x2ff: RAM
0x300-0x3ff: IO

Memory access is granted with the `ldr` and `str` instructions. The address is formed by the 2bit
index flag `ix` and an 8bit register rx in the form `address = (ix,rx)`. The various memory regions
can be accessed by modifying the `ix` flag. The program counter `pc` uses always an index of 0x0
and the stack pointer `sp` uses always an index of 0x1.

IO is accessed like memory. ScottE supports up to eight devices, each of which can have 32B of
space for data access and control.


Clocking
--------

Each instruction is executed within two clock ticks or one cycle. The first tick is used for
instruction fetch, the second tick is used for the execution. Read signals are always set and
data has time for one clock high or low phase to travel. Write is performed on the falling edge
of the clock. The only exception is the program counter `pc` which is always written on the rising
edge.

  | ifetch  |  exec   |

  +----+    +----+    +--
  |    |    |    |    |
--+    +----+    +----+
 -1-  -2-  -3-  -4-

Each cycle starts with the rising edge of the instruction fetch phase (1). At this point the
program counter `pc` is updated with the address of the next instruction which is stored in the
`npc` register. The address is sent to the ROM and the instruction is written to the instruction
register `ir` on the falling edge of ifetch (2). At the same point the `npc` register is updated
and holds the incremented value of `pc`. During the next low phase the control unit updates the 
microinstruction.
If an instruction uses an 8bit constant then this value is read from ROM during the rising edge of
the execution phase (3). The procedure is the same as in ifetch: `pc` is written on the rising edge,
the immediate value is loaded during the high phase, `npc` is updated one more time on the falling
edge. If the instruction isn't followed by a constant, then at (3) nothing happens. Data has time
from (2) to (4) to flow through the data path and memory unit. In any case, data is written to its
destination on the falling edge of exec (4). At this point the cycle is finished (the low phase
of exec is not used).


Instruction Formats
-------------------

Each instruction is 8bit wide, with those ones followed by an 8bit constant beeing an exception.
All instructions follow a simple format. Some instructions may ignore the register fields and use
the bits for different purposes.

    7 6 5 4 3 2 1 0
R: |opcode |ra |rb |
M: |opcode |  misc |

Having only a 4bit wide opcode, ScottE v4 has only 16 different instructions.


Instruction Overview
--------------------

0000 0x xx:  nop            ->  do nothing
0000 10 nn:  six  nn        ->  ix = nn
0000 11 xx:  halt           ->  ignore clock
0001 ra xx:  data ra, imm8  ->  ra = [pc+1]; npc = pc+2
0010 ra rb:  ldr  ra, [rb]  ->  ra = [(ix,rb)]
0011 ra rb:  str  ra, [rb]  ->  [(ix,rb)] = ra
0100 ra rb:  jalr ra        ->  npc = rb; ra = pc+1
0101  cond:  br   imm8      ->  npc = test(cond,flags) ? pc+1 + [pc+1] : pc+2
0110 ra xx:  push ra        ->  [--sp] = ra
0111 ra xx:  pop  ra        ->  ra = [sp++]

1000 ra rb:  add  ra, rb    ->  ra = ra + rb  (vcsz)
1001 ra rb:  sub  ra, rb    ->  ra = ra - rb  (vcsz)
1010 ra rb:  shl  ra, rb    ->  ra = rb << 1  (0csz)
1011 ra rb:  shr  ra, rb    ->  ra = rb >> 1  (0csz)
1100 ra rb:  and  ra, rb    ->  ra = ra & rb  (00sz)
1101 ra rb:  orr  ra, rb    ->  ra = ra | rb  (00sz)
1110 ra rb:  xor  ra, rb    ->  ra = ra ^ rb  (00sz)
1111 ra rb:  cmp  ra, rb    ->       ra - rb  (vcsz)


Microinstructions
-----------------

Each instruction's opcode is used as an address to a ROM containing the corresponding microinstructions.

sp_inc/dec:  increases or decreases the stack pointer `sp` on next update
sp_w:        if set, the stack pointer `sp` will be updated
mux_sp:      selects the `sp` or modified `sp` as address
ix_w:        if set, the index flags will be updated
aluop:       specifies the operation for the ALU
fr_w:        if set, the ALU flags will be stored in the flag register `fr`
mux_rd:      selects the input for rd (00 -> alu, 01 -> bus, 1x -> pc)
mux_rb:      selects the input for rb (0 -> reg, 1 -> bus)
mux_ra:      selects the input for ra (0 -> reg, 1 -> pc)
rd_w:        if set, the destination register will be updated
pc_w:        if set, the program counters `pc` and `npc` will be both updated during exec phase
branch:      if set, the flags will be matched against the condition of the instruction
             on positive result, the `npc` register will be updated with a value from the ALU
mux_npc:     if set, the `npc` register will be updated with a value from the ALU instead of pc+1
mux_addr:    selects the input for the address (00 -> (00,pc), 01 -> (ix,alu), 1x -> (01,sp))
bus_ld/str:  selects whether the memory will be loaded or stored
bus_en:      if set, access to memory is enabled
halt:        if set, the processor will stop (requires the instruction's `cond` field to be set to 0xf)

Further signals are extracted directly from the instruction fields.

brop:        selects the branch condition that is matched against the flags
sel_ra:      selects a register in the register file for input A
sel_rb:      selects a register in the register file for input B
sel_rd:      selects the destination register in the register file
ix:          selects a region for the `ix` register
cin:         carry-in for the ALU


Instructions
------------

NOP
instr:  |0000 0x xx|
desc:   Do nothing.
macro:  ---
micro:  ---


SIX  <region>
instr:  |0000 10 nn|
desc:   Set index. Sets the memory region for future LDR and STR instructions.
macro:  ix = nn  // region: ROM -> 00, STACK -> 01, RAM -> 10, IO -> 11
micro:  ix_w = 1;


HALT
instr:  |0000 11 xx|
desc:   Ignore the clock until resume.
macro:  halt
micro:  halt = 1; ix_w = 1;


DATA RA, IMM8
instr:  |0001 ra xx|   imm8   |
desc:   Load the next byte to register RA.
macro:  ra = rom[pc+1]; npc = pc+2
micro:  pc_w = 1; mux_addr = pc; bus_en = 1; bus_ld/st = 0; mux_rb = bus; aluop = mov; mux_rd = alu; rd_w = 1;


LDR  RA, [RB]
instr:  |0010 ra rb|
desc:   Loads data from the active memory region at the address stored in RB to the register RA.
macro:  ra = [(ix,rb)]
micro:  mux_addr = alu; bus_en = 1; bus_ld/st = 0; mux_rb = reg; aluop = mov; mux_rd = bus; rd_w = 1;


STR  RA, [RB]
instr:  |0011 ra rb|
desc:   Stores data from the register RA to the active memory region at the address stored in RB.
macro:  [(ix,rb)] = ra
micro:  mux_addr = alu; bus_en = 1; bus_ld/st = 1; mux_rb = reg; aluop = mov;


JALR RA
instr:  |0100 ra rb|
desc:   Jump and link. Swaps the values of RA and PC.
macro:  npc = rb; ra = pc+1  // usually rb will be the same register as ra
micro:  mux_npc = alu; pc_w = 1; mux_rb = reg; aluop = mov; mux_rd = pc; rd_w = 1;


B<cond>  IMM8
instr:  |0101  cond|   imm8   |
desc:   Conditionl branch. The address is calculated from PC and the offset stored in the next byte.
macro:  if true: npc = pc+1 + rom[pc+1]  else: npc = pc+2
micro:  branch = 1; pc_w = 1; mux_addr = pc; bus_en = 1; bus_ld/st = 0; mux_ra = pc; mux_rb = bus; aluop = add;
-----+------+------+-----------------------------
cond | bits | test | description    
-----+------+------+-----------------------------
BR   | 0000 | true | branch always
BZS  | 0001 | z==1 | branch if zero flag set
BSS  | 0010 | s==1 | branch if sign flag set
BVS  | 0011 | v==1 | branch if overflow flag set
BCS  | 0100 | c==1 | branch if carry flag set
BEQ  | 0001 | z==1 | branch if equal
BLTU | 0100 | c==1 | branch if uint <
BGEU | 0101 | c==0 | branch if uint >=
BLT  | 0110 | v!=s | branch if int <
BGE  | 0111 | v==s | branch if int >=
-----+------+------+-----------------------------


PUSH RA
instr:  |0110 ra xx|
desc:   Pushes the value from register RA on the top of the stack.
macro:  stack[--sp] = ra
micro:  mux_addr = sp; bus_en = 1; bus_ld/st = 1; mux_sp = 1; sp_w = 1; sp_inc/dec = 1;


POP  RA
instr:  |0111 ra xx|
desc:   Pops the top element of the stack to the register RA.
macro:  ra = stack[sp++]
micro:  mux_addr = sp; bus_en = 1; bus_ld/st = 0; mux_rd = bus; rd_w = 1; mux_sp = 0; sp_w = 1; sp_inc/dec = 0;


ADD  RA, RB
instr:  |1000 ra rb|
desc:   Adds the value in RB to RA and stores the result in RA.
macro:  ra = ra + rb  (fr=[vcsz])
micro:  mux_ra = reg; mux_rb = reg; aluop = add; mux_rd = alu; rd_w = 1;


SUB  RA, RB
instr:  |1001 ra rb|
desc:   Subtracts the value in RB from RA and stores the result in RA.
macro:  ra = ra - rb  (fr=[vcsz])
micro:  mux_ra = reg; mux_rb = reg; aluop = sub; fr_w = 1; mux_rd = alu; rd_w = 1;


SHL  RA, RB
instr:  |1010 ra rb|
desc:   Shifts the value in RB left by one bit and stores the result in RA.
macro:  ra = rb << 1  (fr=[0csz])
micro:  mux_rb = reg; aluop = shl; fr_w = 1; mux_rd = alu; rd_w = 1;


SHR  RA, RB
instr:  |1011 ra rb|
desc:   Shifts the value in RB right by one bit and stores the result in RA.
macro:  ra = rb >> 1  (fr=[0csz])
micro:  mux_rb = reg; aluop = shr; fr_w = 1; mux_rd = alu; rd_w = 1;


AND  RA, RB
instr:  |1100 ra rb|
desc:   Performs a logical AND between RA and RB and stores the result in RA.
macro:  ra = ra & rb  (fr=[00sz])
micro:  mux_ra = reg; mux_rb = reg; aluop = and; fr_w = 1; mux_rd = alu; rd_w = 1;


ORR  RA, RB
instr:  |1101 ra rb|
desc:   Performs a logical OR between RA and RB and stores the result in RA.
macro:  ra = ra | rb  (fr=[00sz])
micro:  mux_ra = reg; mux_rb = reg; aluop = orr; fr_w = 1; mux_rd = alu; rd_w = 1;


XOR  RA, RB
instr:  |1110 ra rb|
desc:   Performs a logical XOR between RA and RB and stores the result in RA.
macro:  ra = ra ^ rb  (fr=[00sz])
micro:  mux_ra = reg; mux_rb = reg; aluop = xor; fr_w = 1; mux_rd = alu; rd_w = 1;


CMP  RA, RB
instr:  |1111 ra rb|
desc:   Compares the values in RA and RB by subtraction and ignores the result.
macro:  ra - rb  (fr=[00sz])
micro:  mux_ra = reg; mux_rb = reg; aluop = sub; fr_w = 1;

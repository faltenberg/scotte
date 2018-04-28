Microinstructions
=================

Microinstructions are 16bit long and stored in a ROM, that is accessed by the 4bit opcode.
The processor updates the PC on the rising edge and everything on the falling edge. Thus all data
is processed during the high phase, the low phase is not used. When immediate values need to be
read from the ROM, the execution is stalled by one cycle. At the end of the next cycle the
instruction will have an invalid microinstruction during the low phase, which is not a big deal,
but should be considered.

Format
------

15...12:  halt       stall      branch     mux_pc
11...08:  io_en      ram_en     ram_r/w    reg_w
07...04:  mux_rd[1]  mux_rd[0]  mux_ra     mux_rb
03...00:  fr_w       op[2]      op[1]      op[0]


halt=1:    processor will stop
stall=1:   processor will use current instruction for one more cycle
branch=1:  if flags == instr[cond]: npc = alu.rd else: npc = pc+1
mux_pc=0:  npc = pc+1
mux_pc=1:  npc = alu.rd

io_en=1:   bus is used to access io devices
ram_en=1:  bus is used to access memory
ram_r/w=0: reg[ra] = ram[alu.rd]
ram_r/w=1: ram[alu.rd] = reg[ra]
reg_w=1:   reg[ra] = mux_rd

mux_rd=0x: reg[ra] = alu
mux_rd=10: reg[ra] = pc+1
mux_rd=11: reg[ra] = bus

mux_ra=0:  alu.ra = reg[ra]
mux_ra=1:  alu.ra = pc
mux_rb=0:  alu.rb = reg[rb]
mux_rb=1:  alu.rb = rom

fr_w=1:    fr = alu.flags
op=xyz:    alu.op = xyz


Microprograms
=============

0000: mov (mov ra, rb  ->  ra = rb)
  mux_rb = reg; alu.op = mov; mux_rd = alu; reg_w = 1;

0001: data (data ra, imm8  ->  ra = rom[pc++])
  stall; mux_rb = rom; alu.op = mov; mux_rd = alu; reg_w = 1;

0010: ldr (ldr ra, [rb]  ->  ra = ram[rb])
  mux_rb = reg; alu.op = mov; ram_en = 1; ram_r/w = 0; mux_rd = bus; reg_w = 1;

0011: str (str ra, [rb]  ->  ram[rb] = ra)
  mux_rb = reg; alu.op = mov; ram_en = 1; ram_r/w = 1;

0100: jalr (jalr ra  ->  swap(pc, ra))
  mux_rb = reg; alu.op = mov; mux_pc = alu; mux_rd = pc; reg_w = 1;

0101: b<cond> (b<cond> imm8  ->  if <cond>: pc = pc+rom[pc] else: pc++)
  stall; mux_ra = pc; mux_rb = rom; alu.op = add; branch = 1;

0110: halt (halt  ->  halt)
  halt = 1;

0111: io
0111 ra 00: in  ra, data (ra = io[active].data)
0111 ra 01: in  ra, addr (ra = io[active].addr)
0111 ra 10: out ra, data (io[active].data = ra)
0111 ra 11: out ra, addr (io[ra].active = true)
  io_en = 1; mux_rd = bus;

1000: add (add ra, rb  ->  ra = ra + rb, fr=[vcsz])
1001: sub (sub ra, rb  ->  ra = ra - rb, fr=[vcsz])
  mux_ra = reg; mux_rb = reg; alu.op = add|sub; fr_w = 1; mux_rd = alu; reg_w = 1;

1010: shl (shl ra, rb  ->  ra = rb << 1; fr=[0csz])
1011: shr (shr ra, rb  ->  ra = rb >> 1; fr=[0csz])
  mux_rb = reg; alu.op = shl|shr; fr_w = 1; mux_rd = alu; reg_w = 1;

1100: and (and ra, rb  ->  ra = ra & rb, fr=[00sz])
1101: orr (orr ra, rb  ->  ra = ra | rb, fr=[00sz])
1110: xor (xor ra, rb  ->  ra = ra ^ rb, fr=[00sz])
  mux_ra = reg; mux_rb = reg; alu.op = and|orr|xor; fr_w = 1; mux_rd = alu; reg_w = 1;

1111: cmp (cmp ra, rb  ->  ra - rb, fr=[vcsz])
  mux_ra = reg; mux_rb = reg; alu.op = sub; fr_w = 1;

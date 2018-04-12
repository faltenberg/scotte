Microinstructions
=================

Microinstructions are 32bit long and stored in ROM that is accessed via a 7bit mPC register.
At each cycle the mPC register is set to a new value from one of three possible sources that are
selected by the configurable multiplexer MUX.
1. mPC is send to an adder and the incremented result is stored back.
2. mPC is set to a constant address that is stored in the ADDR field of the microinstruction itself.
3. mPC is generated from the opcode of the current instruction in the IR register. This is used
   to jump to the microprogram in the ROM that will execute the necessary steps to simulate
   the instruction in IR.

Bit 7 of mPC encodes the state the instruction is in. The processor has two stage: an ifetch and an
execution stage. The ifetch microprogram is stored at the beginning of the ROM so the processor can
start properly after a reset. All microprograms that are associated with some macroinstruction have
bit 7 set to 1. The processor switches between the ifetch and execution state when the ISTATE bit
of a microinstruction is set to 1. Thus all microprograms start at address 0x40. Each macroprogram
must end with a microinstruction that has ISTATE set to 1, so the processor can switch back to the
ifetch state.

Bit 1 and 0 of mPC are used to step through a microprogram. Thus each micorprogram must end within
4 microinstruction. If more steps are needed to simulate a macroinstruction a microprogram can
continue by jumping to an address within 0x04 and 0x39, which are pretty much empty. In total most
instructions will thus finish after 8 cycles including the ifetch stage.

The remaining bits 6, 5, 4 and 3 are free and can be loaded from the opcode of a macroinstruction.
That allows the processor to support up to 16 different instructions. With conditional jumps
depending on the arguments of a macroinstruction more macroinstructions can be supported.


Format
------

31...28:  ISTATE   ___      MUX[1]   MUX[0]
27...24:  ___      ADDR[6]  ADDR[5]  ADDR[4]
23...20:  ADDR[3]  ADDR[2]  ADDR[1]  ADDR[0]
19...16:  halt     ram_r    ram_w    mar_w
15...12:  ir_w     pc_r     pc_w     fr_w
11...08:  rd_r     ra_w     rb_w     bus0
07...04:  io       rx_r     rx_w     rx
03...00:  cin      op[2]    op[1]    op[0]

ISTATE=1: switch processor from ifetch to exec and vice versa
ADDR=XY:  address for mPC
MUX=00: mPC = mPC+1
MUX=01: mPC = ir.args == flags ? ADDR : mPC+1
MUX=10: mPC = ADDR
MUX=11: mPC = [ state, ir.opcode, 0, 0 ]

halt=1:  processor will stop
ram_r=1: bus = ram[mar]
ram_w=1: ram[mar] = bus
mar_w=1: mar = bus

ir_w=1:  ir = bus
pc_r=1:  bus = pc
pc_w=1:  pc = bus
fr_w=1:  fr = alu.flags

rd_r=1:  bus = rd
ra_w=1:  ra = bus
rb_w=1:  rb = bus or zero
bus0=0:  rb = bus
bus0=1:  rb = zero

io=1:    bus is used to access io devices
rx_r=1:  bus = reg[rx]
rx_w=1:  reg[rx] = bus
rx=0:    rx = ir.ra
rx=1:    rx = ir.rb

cin=0:   alu.cin = 0
cin=1:   alu.cin = 1
op=xyz:  alu.op = xyz


Microprograms
=============

ifetch:
  bus0 = 1; rb_w = 1; ra_w = 1; pc_r = 1; mar_w = 1;
  rd_r = 1; pc_w = 1; op = 100; cin = 1;
  ram_r = 1; ir_w = 1; ISTATE = 1; MUX = 11; ADDR = 0x00

instrEnd:
  ISTATE = 1; MUX = 10; ADDR = 0x01


0000: mov (mov ra, rb  ->  ra = rb)
  rx = rb; rx_r = 1; ra_w = 1;
  rx = ra; rx_w = 1; rd_r = 1; op = 000; cin = 0; END;

0001: data (data rb, imm8  ->  rb = ram[pc++])
  bus0 = 1; rb_w = 1; pc_r = 1; ra_w = 1;  mar_w = 1;
  rd_r = 1; pc_w = 1; op = 100; cin = 1;
  rx = rb; rx_w = 1; ram_r = 1; END;

0010: ldr (ldr ra, [rb]  ->  ra = ram[rb])
  rx = rb; rx_r = 1; mar_w = 1;
  rx = ra; rx_w = 1; ram_r = 1; END;

0011: str (str ra, [rb]  ->  ram[rb] = ra)
  rx = rb; rx_r = 1; mar_w = 1;
  rx = ra; rx_r = 1; ram_w = 1; END;

0100: jalr (jalr rb  ->  swap(pc, rb))
  pc_r = 1; ra_w = 1;
  rx = rb; rx_r = 1; pc_w = 1;
  rx = rb; rx_w = 1; rd_r = 1; op = 000; cin = 0; END;

0101: b<cond> (b<cond> imm8  ->  if <cond>: pc = pc+ram[pc] else: pc++)
  pc_r = 1; ra_w = 1; mar_w = 1; MUX = 01; ADDR = jump;
  continue: bus0 = 1; rb_w = 1; pc_w = 1; rd_r = 1; op = 100; cin = 1; END;
  jump:     bus0 = 0; rb_w = 1; ram_r = 1;
            pc_w = 1; rd_r = 1; op = 100; cin = 0; END;

0110: halt (halt  ->  halt)
  halt = 1; END;  // jump to 0x00 so the machine is proper when resumed

0111: io
0111 00 rb: in  data, rb (rb = io[active].data)
0111 01 rb: in  addr, rb (rb = io[active].addr)
0111 10 rb: out data, rb (io[active].data = rb)
0111 11 rb: out addr, rb (io[rb].active = true)
  io = 1; rx = rb;

1000: add (add ra, rb  ->  ra = ra + rb, fr=[vcsz])
1001: sub (sub ra, rb  ->  ra = ra - rb, fr=[vcsz])
  ra_w = 1; rx = ra; rx_r = 1;
  rb_w = 1; rx = rb; rx_r = 1;
  rx = ra; rx_w = 1; rd_r = 1; op = 100|101; cin = 0; flag_w = 1; END;

1010: shl (shl ra, rb  ->  ra = rb << 1; fr=[0csz])
1011: shr (shr ra, rb  ->  ra = rb >> 1; fr=[0csz])
  ra_w = 1; rx = rb; rx_r = 1;
  rx = ra; rx_w = 1; rd_r = 1; op = 110|111; cin = 0; flag_w = 1; END

1100: and (and ra, rb  ->  ra = ra & rb, fr=[00sz])
1101: orr (orr ra, rb  ->  ra = ra | rb, fr=[00sz])
1110: xor (xor ra, rb  ->  ra = ra ^ rb, fr=[00sz])
  ra_w = 1; rx = ra; rx_r = 1;
  rb_w = 1; rx = rb; rx_r = 1;
  rx = ra; rx_w = 1; rd_r = 1; op = 001|010|011; cin = 0; flag_w = 1; END;

1111: cmp (cmp ra, rb  ->  ra - rb, fr=[vcsz])
  ra_w = 1; rx = ra; rx_r = 1;
  rb_w = 1; rx = rb; rx_r = 1; op = 101; cin = 0; flag_w = 1; END;

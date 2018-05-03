// fibo(n)
// Expects n at address RAM[0x00] and stores the result to RAM[0x01].
//
// Register usage:
// r0: temp
// r1: f1
// r2: f2
// r3: n
fibo:
0x00: ldr  r3, r3   0010 1111   // n = ram[0x00]
0x01: data r1       0001 0100   // f1 = 1
0x02: uint 1        0000 0001
0x03: orr  r2, r1   1101 1001   // f2 = 1

loop:
0x04: data r0       0001 0000   // r0 = 2
0x05: uint 2        0000 0010
0x06: cmp  r3, r0   1111 1100   // if (n < 2)
0x07: bltu          0101 0100   // goto end
0x08: int  0x09     0000 1001   // offset: 0x11-0x08=0x09

0x09: push r1       0110 0100   // f1 -> stack
0x0a: add  r1, r2   1000 0110   // f1 = f1 + f2
0x0b: pop  r2       0111 1000   // f2 = f1

0x0c: data r0       0001 0000   // r0 = 1
0x0d: uint 1        0000 0001
0x0e: sub  r3, r0   1001 1100   // n = n-1
0x0f: br            0101 0000   // goto loop
0x10: int  0xf4     1111 0100   // offset: 0x04-0x10=0xf4

end:
0x11: data r0       0001 0000   // r0 = 0x01
0x12: uint 0x01     0000 0001
0x13: str  r1, [r0] 0011 0100   // ram[0x01] = f1
0x14: halt          0000 ffff   // halt


// Runtime v4: 2 ticks per cycle, 1 cycle per instruction
// fibo(0) =  1 - instructions =   9 - time (@16Hz): 0min02s, 0.2s/instr
// fibo(1) =  1 - instructions =   9 - time (@16Hz): 0min02s, 0.2s/instr
// fibo(2) =  2 - instructions =  18 - time (@16Hz): 0min05s, 0.3s/instr
// fibo(3) =  3 - instructions =  27 - time (@16Hz): 0min07s, 0.3s/instr
// fibo(4) =  5 - instructions =  36 - time (@16Hz): 0min09s, 0.2s/instr
// fibo(5) =  8 - instructions =  45 - time (@16Hz): 0min11s, 0.2s/instr
// fibo(6) = 13 - instructions =  54 - time (@16Hz): 0min14s, 0.3s/instr
// fibo(7) = 21 - instructions =  63 - time (@16Hz): 0min16s, 0.2s/instr

// Runtime v3: 1 tick per cycle, 1-2 cylce/s per instruction
// fibo(0) =  1 - instructions =   9 - time (@16Hz): 0min02s, 0.2s/instr
// fibo(1) =  1 - instructions =   9 - time (@16Hz): 0min02s, 0.2s/instr
// fibo(2) =  2 - instructions =  19 - time (@16Hz): 0min04s, 0.2s/instr
// fibo(3) =  3 - instructions =  29 - time (@16Hz): 0min05s, 0.2s/instr
// fibo(4) =  5 - instructions =  39 - time (@16Hz): 0min07s, 0.2s/instr
// fibo(5) =  8 - instructions =  49 - time (@16Hz): 0min09s, 0.2s/instr
// fibo(6) = 13 - instructions =  59 - time (@16Hz): 0min11s, 0.2s/instr
// fibo(7) = 21 - instructions =  69 - time (@16Hz): 0min13s, 0.2s/instr

// Runtime v2: 2 ticks per cycle, 4-7 cycles per instruction
// fibo(0) =  1 - instructions =   9 - time (@16Hz): 0min15s, 1.7s/instr
// fibo(1) =  1 - instructions =   9 - time (@16Hz): 0min15s, 1.7s/instr
// fibo(2) =  2 - instructions =  19 - time (@16Hz): 0min25s, 1.3s/instr
// fibo(3) =  3 - instructions =  29 - time (@16Hz): 0min40s, 1.4s/instr
// fibo(4) =  5 - instructions =  39 - time (@16Hz): 0min55s, 1.4s/instr
// fibo(5) =  8 - instructions =  49 - time (@16Hz): 1min05s, 1.3s/instr
// fibo(6) = 13 - instructions =  59 - time (@16Hz): 1min20s, 1.4s/instr
// fibo(7) = 21 - instructions =  69 - time (@16Hz): 1min35s, 1.4s/instr

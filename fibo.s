// Register usage:
// r0: f, temp
// r1: f1
// r2: f2
// r3: n
fibo:
0x00: data r3       0001 1100   // load n
0x01: uint n        n=7
0x02: data r1       0001 0100   // f1 = 1
0x03: uint 1        0000 0001
0x04: mov  r2, r1   0000 1001   // f2 = 1

loop:
0x05: data r0       0001 0000   // r0 = 2
0x06: uint 2        0000 0010
0x07: cmp  r3, r0   1111 1100   // if (n < 2)
0x08: bltu          0101 0100   // goto end
0x09: int  0x0a     0000 1010   // offset: 0x13-0x09=0x0a

0x0a: mov  r0, r1   0000 0001   // f = f1
0x0b: add  r0, r2   1000 0010   // f = f1 + f2
0x0c: mov  r2, r1   0000 1001   // f2 = f1
0x0d: mov  r1, r0   0000 0100   // f1 = f

0x0e: data r0       0001 0000   // r0 = 1
0x0f: uint 1        0000 0001
0x10: sub  r3, r0   1001 1100   // n = n-1
0x11: br            0101 0000   // goto loop
0x12: int  0xf3     1111 0011   // offset: 0x05-0x12=0xf3

end:
0x13: data r0       0001 0000   // r0 = 0x01
0x14: uint 0x01     0000 0001
0x15: str  r1, [r0] 0011 0100   // ram[0x01] = f1
0x16: halt          0110 0000   // halt

// Runtime v3:
// fibo(0) =  1 - instructions = 0x09  9 - time (@16Hz): 0min02s, 0.2s/instr
// fibo(1) =  1 - instructions = 0x09  9 - time (@16Hz): 0min02s, 0.2s/instr
// fibo(2) =  2 - instructions = 0x13 19 - time (@16Hz): 0min04s, 0.2s/instr
// fibo(3) =  3 - instructions = 0x1d 29 - time (@16Hz): 0min05s, 0.2s/instr
// fibo(4) =  5 - instructions = 0x27 39 - time (@16Hz): 0min07s, 0.2s/instr
// fibo(5) =  8 - instructions = 0x31 49 - time (@16Hz): 0min09s, 0.2s/instr
// fibo(6) = 13 - instructions = 0x3b 59 - time (@16Hz): 0min11s, 0.2s/instr
// fibo(7) = 21 - instructions = 0x45 69 - time (@16Hz): 0min13s, 0.2s/instr

// Runtime v2:
// fibo(0) =  1 - instructions = 0x09  9 - time (@16Hz): 0min15s, 1.7s/instr
// fibo(1) =  1 - instructions = 0x09  9 - time (@16Hz): 0min15s, 1.7s/instr
// fibo(2) =  2 - instructions = 0x13 19 - time (@16Hz): 0min25s, 1.3s/instr
// fibo(3) =  3 - instructions = 0x1d 29 - time (@16Hz): 0min40s, 1.4s/instr
// fibo(4) =  5 - instructions = 0x27 39 - time (@16Hz): 0min55s, 1.4s/instr
// fibo(5) =  8 - instructions = 0x31 49 - time (@16Hz): 1min05s, 1.3s/instr
// fibo(6) = 13 - instructions = 0x3b 59 - time (@16Hz): 1min20s, 1.4s/instr
// fibo(7) = 21 - instructions = 0x45 69 - time (@16Hz): 1min35s, 1.4s/instr

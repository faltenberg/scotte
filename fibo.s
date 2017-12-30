// Register usage:
// r0: f, temp
// r1: f1
// r2: f2
// r3: n
fibo:
0x00: data r3       0010 0011   // load n
0x01: n             n=7
0x02: data r1       0010 0001   // f1 = 1
0x03: 1             0000 0001
0x04: data r2       0010 0010   // f2 = 1
0x05: 1             0000 0001

loop:
0x06: data r0       0010 0000   // r0 = 2
0x07: 2             0000 0010
0x08: cmp r0, r3    1111 0011   // if (2 > n)
0x09: bgt           0101 0100   // goto end
0x0a: 0x17          0001 0111

body:
0x0b: xor r0, r0    1110 0000   // f = 0
0x0c: add r0, r1    1000 0001   // f = f1
0x0d: add r0, r2    1000 0010   // f = f1 + f2

0x0e: xor r2, r2    1110 1010   // f2 = 0
0x0f: add r2, r1    1000 1001   // f2 = f1
0x10: xor r1, r1    1110 0101   // f1 = 0
0x11: add r1, r0    1000 0100   // f1 = f

0x12: xor r0, r0    1110 0000   // r0 = 0
0x13: not r0, r0    1011 0000   // r0 = -1
0x14: add r3, r0    1000 1100   // n += -1
0x15: br            0101 0000   // goto loop
0x16: 0x06          0000 0110

end:
0x17: data r0       0010 0000   // r0 = 0x01
0x18: 0x01          0000 0001
0x19: str r1, [r0]  0001 0100   // ram[0x01] = f1
0x1a: halt          0110 1111   // halt


// Runtime:
// fibo(0) =  1  -  instructions = 0x09   9  -  time (@16Hz): 0min15s, 1.5s/instr
// fibo(1) =  1  -  instructions = 0x09   9  -  time (@16Hz): 0min15s, 1.5s/instr
// fibo(2) =  2  -  instructions = 0x17  23  -  time (@16Hz): 0min35s, 1.5s/instr
// fibo(3) =  3  -  instructions = 0x25  37  -  time (@16Hz): 0min55s, 1.5s/instr
// fibo(4) =  5  -  instructions = 0x33  51  -  time (@16Hz): 1min15s, 1.5s/instr
// fibo(5) =  8  -  instructions = 0x41  65  -  time (@16Hz): 1min35s, 1.5s/instr
// fibo(6) = 13  -  instructions = 0x4f  79  -  time (@16Hz): 2min00s, 1.5s/instr
// fibo(7) = 21  -  instructions = 0x5d  93  -  time (@16Hz): 2min20s, 1.5s/instr

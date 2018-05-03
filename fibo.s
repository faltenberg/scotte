// fibo(n)
// Expects n at address RAM[0x00] and stores the result to RAM[0x01].
//
// Register usage:
// r0: temp
// r1: f1
// r2: f2
// r3: n
fibo:
0x00: ldr  r3, [r3]  0010 1111   // n = ram[0x00]
0x01: xor  r1, r1    1110 0101   // f1 = 0
0x02: data r2        0001 1000   // f2 = 1
0x03: uint 1         0000 0001

loop:
0x04: data r0        0001 0000   // r0 = 1
0x05: uint 1         0000 0001
0x06: cmp  r3, r0    1111 1100   // if (n < 1)
0x07: bltu           0101 0100   // goto end
0x08: int  0x09      0000 1001   // offset: 0x11-0x08=0x09

0x09: push r1        0110 0100   // f1 -> stack
0x0a: add  r1, r2    1000 0110   // f1 = f1 + f2
0x0b: pop  r2        0111 1000   // f2 = f1

0x0c: data r0        0001 0000   // r0 = 1
0x0d: uint 1         0000 0001
0x0e: sub  r3, r0    1001 1100   // n = n-1
0x0f: br             0101 0000   // goto loop
0x10: int  0xf4      1111 0100   // offset: 0x04-0x10=0xf4

end:
0x11: data r0        0001 0000   // r0 = 0x01
0x12: uint 0x01      0000 0001
0x13: str  r1, [r0]  0011 0100   // ram[0x01] = f1
0x14: halt           0000 ffff   // halt

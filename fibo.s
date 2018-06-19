// fibo(n)
// n in ROM, pushes result on the stack
//
// Register usage:
// r0: holds value 1 for various occasions
// r1: f1
// r2: f2
// r3: n, is counted down
fibo:
0x00: data r3        0001 1100   // addr = 0x00
0x01: uint 0x00      0000 0000
0x02: six  ram       0000 1010   // ix = 10
0x03: ldr  r3, [r3]  0010 1111   // n = ram[0x00]
0x04: xor  r1, r1    1110 0101   // f1 = 0
0x05: data r2        0001 1000   // f2 = 1
0x06: uint 1         0000 0001
0x07: data r0        0001 0000   // r0 = 0
0x08: uint 1         0000 0001

loop:
0x09: cmp  r3, r0    1111 1100   // if (n < 1)
0x0a: bltu           0101 0100   // goto end
0x0b: int  0x07      0000 0111   // offset: 0x12-0x0b=0x07

0x0c: push r1        0110 0100   // f1 -> stack
0x0d: add  r1, r2    1000 0110   // f1 = f1 + f2
0x0e: pop  r2        0111 1000   // f2 = f1

0x0f: sub  r3, r0    1001 1100   // n = n-1
0x10: br             0101 0000   // goto loop
0x11: int  0xf8      1111 1000   // offset: 0x09-0x11=0xf8

end:
0x12: str  r1, [r0]  0011 0100   // ram[0x01] = result
0x13: halt           0000 ffff   // halt

0x14: br             0101 0000   // goto fibo
0x15: int -21        1110 1011   // offset: 0x00-0x15=0xeb

n:
0x20: uint X         0000 0000

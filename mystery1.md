(the CPU is AMD Ryzen Threadripper 3970X 32-Core Processor)

### 2.1

Probably closer to 1.

### 2.2

```
-O0: 1000000000 iterations, 2640744649 cycles, 2.64 cycles/iteration
-O2: 1000000000 iterations, 74 cycles, 0.00 cycles/iteration
```

The -O2 version basicaly optimized the sum away:

```
0000108f  0f31               rdtsc
00001091  4889c1             mov     rcx, rax
00001094  48c1e220           shl     rdx, 0x20
00001098  4809d1             or      rcx, rdx
0000109b  0f31               rdtsc
```

The -O0 version is also problematic, since it spills the registers to the stack:

```
000011b7  8b45d4             mov     eax, dword [rbp-0x2c {var_34}]
000011ba  4898               cdqe
000011bc  480145d8           add     qword [rbp-0x28 {var_30}], rax
```

### 2.3

```
-O0: 1000000000 iterations, 2642594797 cycles, 2.64 cycles/iteration
     1651806633 169000000000
-O2: 1000000000 iterations, 74 cycles, 0.00 cycles/iteration
     1651806673 209000000000
```

The -O2 version still managed to optimize the loop away.
This time it uses a multiplication by `kIterations` outside of the loop
to get the final result:

```
0000108d  4989c4             mov     r12, rax
...
000010de  450fb6c4           movzx   r8d, r12b
000010e7  4d69c000ca9a3b     imul    r8, r8, 1000000000
...
00001101  e86affffff         call    __fprintf_chk
```


The -O0 version remains the same.

### 2.4

```
-O0: 1000000000 iterations, 6297658075 cycles, 6.30 cycles/iteration
     1651806729 9000000000
-O2: 1000000000 iterations, 861000915 cycles, 0.86 cycles/iteration
     1651806771 51000000000
```

The loop from the -O2 version is now not optimized and consists of
a memory access, an addition, and a branch. Apparently they all run
in under one cycle:

```
000010b0  486344240c         movsxd  rax, dword [rsp+0xc {incr}]
000010b5  4801c3             add     rbx, rax
000010b8  83ea01             sub     edx, 0x1
000010bb  75f3               jne     0x10b0
```

The slowdown in the -O0 version is absolutely baffling. The only
change in the generated assembly is the different memory placement
of `i` and `incr`.

Before: `i` is at `[rbp-0x30]`, `incr` is at `[rbp-0x2c]`

Now:    `i` is at `[rbp-0x2c]`, `incr` is at `[rbp-0x30]`

I distilled this example into a pure assembly program with no dependencies and tried to explain the performance difference [here](/mystery1_24_amd_puzzler/).
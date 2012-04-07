# LLVM backend for DCPU-16 #

DCPU-16 is the processor from Mojang's new game [0x10c](http://0x10c.com/).
This project has a goal to make a full-featured LLVM backend for DCPU-16 and
port Clang to support this architecture.

Currently, llvm backend and Clang support are only partially implemented,
but simple programs work.

Below are the instructions how to build and try (tested on Ubuntu 11.10 x86_64)

First, of all, you need to install prerequisites:

    sudo apt-get install gcc g++ git subversion git-svn\
     perl gawk expect tcl texinfo bison autoconf automake cmake

Note, that Arch Linux users experience [the issue with cmake](https://github.com/krasin/llvm-dcpu16/issues/43).

Next, get the sources and build it:

    git clone git://github.com/krasin/llvm-dcpu16.git # Checkout LLVM
    cd llvm-dcpu16/tools
    git clone git://github.com/krasin/clang-dcpu16.git clang # Checkout Clang
    mkdir ../cbuild
    cd ../cbuild
    cmake ..
    make -j4

It should build w/o a problem. Please, file an issue with the output, in case you have any troubles with this step.

Consider the following C file:

fib.c:

    int fib(int n) {
      int cur = 1;
      int prev = 1;
      for (int i = 0; i < n; i++) {
        int next = cur+prev;
        prev = cur;
        cur = next;
      }
      return cur;
    }

Now, let's translate C to DCPU16 assembly:

    bin/clang -ccc-host-triple dcpu16 -S fib.c

fib.s:

        .file    "fib.o"
        .text
        .globl    fib
        .align    2
        .type    fib,@function
    fib:                                    ; @fib
    ; BB#0:                                 ; %entry
      SUB C, 10 ; The Notch order
      SET [8+C], X ; The Notch order
      SET [6+C], 1 ; The Notch order
      SET [4+C], 1 ; The Notch order
      SET [2+C], 0 ; The Notch order
    .LBB0_1:                                ; %for.cond
                                            ; =>This Inner Loop Header: Depth=1
      SET J, [2+C] ; The Notch order
      SET O, 65535 ; The Notch order, cmp [8+C], J, start
      IFE J, [8+C] ; The Notch order
      SET O, 0 ; The Notch order
      IFG J, [8+C] ; The Notch order
      SET O, 1 ; The Notch order, end
      IFN O, 65535 ; The Notch order, jge
      SET PC, .LBB0_3 ; The Notch order
    ; BB#2:                                 ; %for.body
                                            ;   in Loop: Header=BB0_1 Depth=1
      SET J, [6+C] ; The Notch order
      ADD J, [4+C] ; The Notch order
      SET [0+C], J ; The Notch order
      SET [4+C], [6+C] ; The Notch order
      SET [6+C], [0+C] ; The Notch order
      ADD [2+C], 1 ; The Notch order
      SET PC, .LBB0_1 ; The Notch order
    .LBB0_3:                                ; %for.end
      SET X, [6+C] ; The Notch order
      ADD C, 10 ; The Notch order
      SET PC, POP ; The Notch order
    .Ltmp0:
        .size    fib, .Ltmp0-fib

Although, this program is perfectly valid, no existing DCPU16 assembly accepts it because of two primary reasons:

- Label declarations in most 'regular' assemblers are defined as label: (colon at the end of line),
  but DCPU16 assemblers prefer :label (colon at the beginning) syntax.
  I have not yet decided what to do here: make hacks to LLVM to teach the new label syntax or
  convince DCPU16 assemblers to accept both formats (which is pretty safe).

- Standard symbol declarations like .file, .text, .size, .align, .globl, .type are currently not supported by DCPU16 assemblers.

So, in order to get your program running, for now, you will have to:

1. replace all label: declarations with :label
2. remove .size, .align, .globl, .type, etc
3. in the beginning of your program, please, put the initialization:

        SET C, SP
        SUB C, 256

You may want find [tools/dcpu16/asm-rewriter.py](https://github.com/krasin/llvm-dcpu16/blob/main/tools/dcpu16/rewrite-asm.py)
useful (it should make the above changes for you!)

This is because SP is not addressable and LLVM backend only uses it as an instruction stack pointer.
For data stack pointer, C register is used.
As you may mention, 256 is the limit for recursion. You may choose your own limit.

So, the program that you can run would look like:

    :init
      SET C, SP
      SUB C, 256
    
    :start
      SET X, 4
      JSR fib         ; call fib(4)
      SET PC, break   ; halt
    
    :fib                                    ; @fib
    ; BB#0:                                 ; %entry
      SUB C, 10
      SET [8+C], X
      SET [6+C], 1
      SET [4+C], 1
      SET [2+C], 0
    :.LBB0_1                                ; %for.cond
                                            ; =>This Inner Loop Header: Depth=1
      SET J, [2+C]
      SET O, 65535
      IFE J, [8+C]
      SET O, 0
      IFG J, [8+C]
      SET O, 1
      IFN O, 65535
      SET PC, .LBB0_3
    ; BB#2:                                 ; %for.body
                                            ;   in Loop: Header=BB0_1 Depth=1
      SET J, [6+C]
      ADD J, [4+C]
      SET [0+C], J
      SET [4+C], [6+C]
      SET [6+C], [0+C]
      ADD [2+C], 1
    
      SET PC, .LBB0_1
    :.LBB0_3                                ; %for.end
      SET X, [6+C]
      ADD  C, 10
      SET PC, POP
    
    :break
      BRK
    
    :crash
      SET PC, crash

You may want to try it in the [online DCPU assembler and debugger by Mappum](http://mappum.github.com/DCPU-16/)
After you compile and run the program, the final state should be:

    ==== REGISTERS: ====
    A:  0000
    B:  0000
    C:  ff00
    X:  0008
    Y:  0000
    Z:  0000
    I:  0000
    J:  0004
    
    PC: 0034
    SP: 0000
    O:  0000
    
    CPU CYCLES: 178
    
    ======= RAM: =======
    0000:*6c21*7c23 0100 9031 7c10 0008 7dc1 0033
    0008: a823 0d21 0008 8521 0006 8521 0004 8121
    0010: 0002 4871 0002 7dd1 ffff 487c 0008 81d1
    0018: 487e 0008 85d1 7ddd ffff 7dc1 002f 4871
    0020: 0006 4872 0004 1d21 0000 4921 0004 0006
    0028: 4921 0006 0000 8522 0002 7dc1 0011 4831
    0030: 0006 a822 61c1 0020[7dc1]0034 0000 0000
    fef0: 0000 0000 0000 0000 0000 0000 0008 0000
    fef8: 0004 0000 0005 0000 0008 0000 0004 0000
    fff8: 0000 0000 0000 0000 0000 0000 0000 0006       	   

X=8 has the value of Fib_4 (you may want to play with the value of argument to fib other than 4).

Enjoy and, please, [report bugs](https://github.com/krasin/llvm-dcpu16/issues)!

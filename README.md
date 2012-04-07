# LLVM backend for DCPU-16 #

DCPU-16 is the processor from Mojang's new game [0x10c](http://0x10c.com/).
This project has a goal to make a full-featured LLVM backend for DCPU-16 and
port Clang to support this architecture.

Currently, llvm backend is only partially implemented, but simple programs work.
Using clang is also possible, but one should target to msp430 to get the LLVM bitcode.

Below are the instructions how to build and try (tested on Ubuntu 11.10 x86_64)

First, of all, you need to install prerequisites:

    sudo apt-get install gcc g++ git subversion git-svn\
     perl gawk expect tcl texinfo bison autoconf automake cmake

Next, get the sources and build it:

    git clone git@github.com:krasin/llvm-dcpu16.git
    cd llvm-dcpu16
    mkdir cbuild
    cd cbuild
    cmake ..
    make -j4

It should build w/o a problem. Please, file an issue with the output, in case you have any troubles with this step.

Now, you have llvm tools built, in particular, bin/llc that translates LLVM bitcode to native code.

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


Assuming that you have a 'normal' clang in the $PATH, let's translate this C program to DCPU16 assembly:

    clang -ccc-host-triple msp430 -c -emit-llvm fib.c
    bin/llc -filetype=asm -mtriple dcpu16 fib.o -o fib.s

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

Enjoy and, please, [report bugs](https://github.com/krasin/llvm-dcpu16/issues)!

# LLVM backend for DCPU-16 #

DCPU-16 is the processor from Mojang's new game [0x10c](http://0x10c.com/).
This project has a goal to make a full-featured LLVM backend for DCPU-16 and
port Clang to support this architecture.

Currently, llvm backend and Clang support are only partially implemented,
but simple programs work.

### [Binary distribution for Linux x64 is available.](https://s3.amazonaws.com/llvm-dcpu16/llvm-dcpu16.v0.0.2.tar.gz) (v0.0.2, 170MB) ###

Tested on Ubuntu 11.10 x86-64.
Please, [let me know](https://github.com/krasin/llvm-dcpu16/issues), if it does not work for you.

Basic Clang usage is:

    path/to/bin/clang -ccc-host-triple dcpu16 -S lala.c -o lala.s

Below are the instructions how to build the toolchain from sources and try:

First, of all, you need to install prerequisites:

    sudo apt-get install gcc g++ git subversion git-svn make\
     perl gawk expect tcl texinfo bison autoconf automake cmake

Note, that when your python executable points to python3 (you can check that by running python --version) 
you have to replace "cmake .." with "cmake  -DPYTHON_EXECUTABLE=/path/to/python2 .." in the following steps (path is /usr/bin/python2 in most cases)

Next, get the sources and build it:

    git clone git://github.com/krasin/llvm-dcpu16.git # Checkout LLVM
    cd llvm-dcpu16/tools
    git clone git://github.com/llvm-dcpu16/clang.git # Checkout Clang
    mkdir ../cbuild
    cd ../cbuild
    cmake ..
    make -j4

It should build w/o a problem. Please, file an issue with the output, in case you have any troubles with this step.

Consider the following C file:

fib.c:

```c
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

int main(void) {
  return fib(5);
}
```

Now, let's translate C to DCPU16 assembly:

    bin/clang -ccc-host-triple dcpu16 -S fib.c -o fib.s

fib.s:

```dasm16
:autoinit    ;;Init data stack register C
      SET C, SP
      SUB C, 256

:autostart
  JSR main
:autohalt SET PC, autohalt
    ; .file "/home/krasin/fib.c"
    ; .align  2
:fib
  SUB  C, 12 ; The Notch order
  SET  [10+C], X ; The Notch order
  SET  [8+C], 1 ; The Notch order
  SET  [6+C], 1 ; The Notch order
  SET  [4+C], 0 ; The Notch order
  SET  [0+C], X ; The Notch order
:.LBB0_1
  SET  J, [4+C] ; The Notch order
  SET  Z, [10+C] ; The Notch order
  SET  O, 65535 ; The Notch order, cmp Z, J, start
  IFE  J, Z ; The Notch order
  SET  O, 0 ; The Notch order
  IFG  J, Z ; The Notch order
  SET  O, 1 ; The Notch order, end
  IFN  O, 65535 ; The Notch order, jge
  SET  PC, .LBB0_4 ; The Notch order
  SET  PC, .LBB0_2 ; The Notch order
:.LBB0_2
  SET  J, [8+C] ; The Notch order
  SET  Z, [6+C] ; The Notch order
  ADD  J, Z ; The Notch order
  SET  [2+C], J ; The Notch order
  SET  J, [8+C] ; The Notch order
  SET  [6+C], J ; The Notch order
  SET  J, [2+C] ; The Notch order
  SET  [8+C], J ; The Notch order
  SET  J, [4+C] ; The Notch order
  ADD  J, 1 ; The Notch order
  SET  [4+C], J ; The Notch order
  SET  PC, .LBB0_1 ; The Notch order
:.LBB0_4
  SET  X, [8+C] ; The Notch order
  ADD  C, 12 ; The Notch order
  SET PC, POP ; The Notch order

  ; .align    2
:main
  SUB  C, 2 ; The Notch order
  SET  [0+C], 0 ; The Notch order
  SET  X, 5 ; The Notch order
  JSR  fib ; The Notch order
  ADD  C, 2 ; The Notch order
  SET PC, POP ; The Notch order
```

You may want to try it the [online deNULL DCPU-16 Assembler, Emulator & Disassembler](http://dcpu.ru/).
Other assemblers may or may not be able to compile the output from DCPU16 LLVM backend.
Hopefully, the situation with the compatibility will improve soon.

After you compile and run the program, the final state would be something like:

    ==== REGISTERS: ====
    A:  0000
    B:  0000
    C:  ff00
    X:  000d
    Y:  0000
    Z:  0005
    I:  0000
    J:  0005
    
    PC: 0005
    SP: 0000
    O:  0000
    
    CPU CYCLES: 5834
    
    ======= RAM: =======
    0000:*6c21*7c23 0100 7c10 003c[7dc1]0005 b023
    0008: 0d21 000a 8521 0008 8521 0006 8121 0004
    0010: 0d21 0000 4871 0004 4851 000a 7dd1 ffff
    0018: 147c 81d1 147e 85d1 7ddd ffff 7dc1 0038
    0020: 7dc1 0022 4871 0008 4851 0006 1472 1d21
    0028: 0002 4871 0008 1d21 0006 4871 0002 1d21
    0030: 0008 4871 0004 8472 1d21 0004 7dc1 0012
    0038: 4831 0008 b022 61c1 8823 8121 0000 9431
    0040: 7c10 0007 8822 61c1 0000 0000 0000 0000
    fef0: 0000 0000 0005 0000 000d 0000 0005 0000
    fef8: 0008 0000 000d 0000 0005 0000 0000 0000
    fff8: 0000 0000 0000 0000 0000 0000 0042 0005

X=13 has the value of Fib_5 (you may want to play other values of argument to fib).

Enjoy and, please, [report bugs](https://github.com/krasin/llvm-dcpu16/issues)!

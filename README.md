# LLVM backend for DCPU-16 #

DCPU-16 is the processor from Mojang's new game [0x10c](http://0x10c.com/).
This project has a goal to make a full-featured LLVM backend for DCPU-16 and
port Clang to support this architecture.

Currently, llvm backend is only partially implemented, but simple programs work.
Using clang is also possible, but one should target to msp430 to get the LLVM bitcode.

Below are the instructions how to build and try (tested on Ubuntu 11.10 x86_64)

First, of all, you need to install prerequisites:

    sudo apt-get install gcc g++ git subversion git-svn\
    perl gawk expect tcl texinfo awk autoconf automake cmake

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
        cur = prev;
      }
      return cur;
    }


Assuming that you have a 'normal' clang in the $PATH, let's it:

    clang -ccc-host-triple msp430 -c -emit-llvm fib.c
    bin/llc -filetype=asm -mtriple dcpu16 fib.o -o fib.s

< currently, the compiler has issues with this test file. I am going to fix them soon >


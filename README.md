# LLVM backend for DCPU-16 #

DCPU-16 is the processor from Mojang's new game [0x10c](http://0x10c.com/).
This project has a goal to make a full-featured LLVM backend for DCPU-16 and
port Clang to support this architecture.

Currently llvm backend and Clang support are nearly fully implemented.

### Simple C SDK ###
You can download a simple C SDK, which includes clang with the [binutils port for dcpu16](https://github.com/frot/binutils-dcpu16).
It is Makefile based and contains a very simple C test program to demonstrate how you can develop your own program.

####Version 0.1####
[Ubuntu 12.04 x86-64](https://github.com/downloads/llvm-dcpu16/llvm-dcpu16/DCPU16-C-SDK-v0.1.tar.gz)

Please, [let us know](https://github.com/llvm-dcpu16/llvm-dcpu16/issues), if it does not work for you.

### Building ###
First, of all, you need to install prerequisites:

    sudo apt-get install gcc g++ git subversion git-svn make\
     perl gawk expect tcl texinfo bison autoconf automake cmake

Note, that when your python executable points to python3 (you can check that by running python --version) 
you have to replace "cmake .." with "cmake  -DPYTHON_EXECUTABLE=/path/to/python2 .." in the following steps (path is /usr/bin/python2 in most cases)

Next, get the sources and build it:

    git clone git://github.com/llvm-dcpu16/llvm-dcpu16.git # Checkout LLVM
    cd llvm-dcpu16/tools
    git clone git://github.com/llvm-dcpu16/clang.git # Checkout Clang
    mkdir ../cbuild
    cd ../cbuild
    cmake ..
    make -j4
    
### Using LLVM-DCPU16 ###
    
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

We generate DCPU16 v1.7 ASM and generate GAS compatible syntax. Most online
assemblers won't work. Please use the [binutils port](https://github.com/frot/binutils-dcpu16) for DCPU16 to assemble and
link your program and then use an DCPU16 v1.7 compatible emulator to test your
program.

Enjoy and, please, [report bugs](https://github.com/llvm-dcpu16/llvm-dcpu16/issues)!

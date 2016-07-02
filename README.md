# LLVM backend for DCPU-16 #

DCPU-16 is the processor from Mojang's new game [0x10c](http://0x10c.com/).
This project has a goal to make a full-featured LLVM backend for DCPU-16 and
port Clang to support this architecture.

Currently llvm backend and Clang support are nearly fully implemented.

### Building ###
First, of all, you need to install prerequisites:

    sudo apt-get install gcc g++ git subversion git-svn make\
     perl gawk expect tcl texinfo bison autoconf automake cmake

Note, that when your python executable points to python3 (you can check that by running python --version) 
you have to replace "cmake .." with "cmake  -DPYTHON_EXECUTABLE=/path/to/python2 .." in the following steps (path is /usr/bin/python2 in most cases)

Next, get the sources and build it:

    git clone git://github.com/FrOSt-Foundation/llvm-dcpu16.git # Checkout LLVM
    mkdir cbuild
    cd cbuild
    cmake ..
    make -j4 # You can replace 4 by your number of logical cores
    
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

We generate DCPU16 v1.7 ASM with GAS compatible syntax. Most online
assemblers won't work. This [binutils port](https://github.com/frot/binutils-dcpu16) is intended to be used with this repository, but at FrOSt-Foundation we use [Yamakaky/dcpu](https://github.com/Yamakaky/dcpu). 

Enjoy and, please, [report bugs](https://github.com/llvm-dcpu16/llvm-dcpu16/issues)!

//===-- DCPU16RegisterInfo.td - DCPU16 Register defs -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the DCPU16 register file
//===----------------------------------------------------------------------===//

class DCPU16Reg<bits<4> num, string n> : Register<n> {
  field bits<4> Num = num;
  let Namespace = "DCPU16";
}

class DCPU16RegWithSubregs<bits<4> num, string n, list<Register> subregs> 
  : RegisterWithSubRegs<n, subregs> {
  field bits<4> Num = num;
  let Namespace = "DCPU16";
}

//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

def PCB  : DCPU16Reg<0,  "r0">;
def SPB  : DCPU16Reg<1,  "C">;
def SRB  : DCPU16Reg<2,  "r2">;
def CGB  : DCPU16Reg<3,  "r3">;
def FPB  : DCPU16Reg<4,  "r4">;
def R1AB : DCPU16Reg<5,  "A">;
def R2BB : DCPU16Reg<6,  "B">;
def R4XB : DCPU16Reg<8,  "X">;
def R5YB : DCPU16Reg<9,  "Y">;
def R6ZB : DCPU16Reg<10, "Z">;
def R7IB : DCPU16Reg<11, "I">;
def R8JB : DCPU16Reg<12, "J">;
def R13B : DCPU16Reg<13, "r13">;
def R14B : DCPU16Reg<14, "r14">;
def R15B : DCPU16Reg<15, "r15">;

def subreg_8bit : SubRegIndex { let Namespace = "DCPU16"; }

let SubRegIndices = [subreg_8bit] in {
def PCW  : DCPU16RegWithSubregs<0,  "r0",  [PCB]>;
def SPW  : DCPU16RegWithSubregs<1,  "C",  [SPB]>;
def SRW  : DCPU16RegWithSubregs<2,  "r2",  [SRB]>;
def CGW  : DCPU16RegWithSubregs<3,  "r3",  [CGB]>;
def FPW  : DCPU16RegWithSubregs<4,  "r4",  [FPB]>;
def R1A  : DCPU16RegWithSubregs<5,  "A",   [R1AB]>;
def R2B  : DCPU16RegWithSubregs<6,  "B",   [R2BB]>;
def R4X  : DCPU16RegWithSubregs<8,  "X",   [R4XB]>;
def R5Y  : DCPU16RegWithSubregs<9,  "Y",   [R5YB]>;
def R6Z  : DCPU16RegWithSubregs<10, "Z",   [R6ZB]>;
def R7I  : DCPU16RegWithSubregs<11, "I",   [R7IB]>;
def R8J  : DCPU16RegWithSubregs<12, "J",   [R8JB]>;
def R13W : DCPU16RegWithSubregs<13, "r13", [R13B]>;
def R14W : DCPU16RegWithSubregs<14, "r14", [R14B]>;
def R15W : DCPU16RegWithSubregs<15, "r15", [R15B]>;
}

def GR8 : RegisterClass<"DCPU16", [i8], 8,
   // Volatile registers
  (add R8JB, R13B, R14B, R15B, R7IB, R6ZB, R5YB, R4XB, R2BB, R1AB,
   // Frame pointer, sometimes allocable
   FPB,
   // Volatile, but not allocable
   PCB, SPB, SRB, CGB)>;

def GR16 : RegisterClass<"DCPU16", [i16], 16,
   // Volatile registers
  (add R8J, R13W, R14W, R15W, R7I, R6Z, R5Y, R4X, R2B, R1A,
   // Frame pointer, sometimes allocable
   FPW,
   // Volatile, but not allocable
   PCW, SPW, SRW, CGW)>
{
  let SubRegClasses = [(GR8 subreg_8bit)];
}


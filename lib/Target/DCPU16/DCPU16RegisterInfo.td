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
def SPB  : DCPU16Reg<1,  "r1">;
def SRB  : DCPU16Reg<2,  "r2">;
def CGB  : DCPU16Reg<3,  "r3">;
def FPB  : DCPU16Reg<4,  "r4">;
def R5B  : DCPU16Reg<5,  "r5">;
def R6B  : DCPU16Reg<6,  "r6">;
def R7B  : DCPU16Reg<7,  "r7">;
def R8B  : DCPU16Reg<8,  "r8">;
def R9B  : DCPU16Reg<9,  "r9">;
def R10B : DCPU16Reg<10, "r10">;
def R11B : DCPU16Reg<11, "r11">;
def R12B : DCPU16Reg<12, "r12">;
def R13B : DCPU16Reg<13, "r13">;
def R14B : DCPU16Reg<14, "r14">;
def R15B : DCPU16Reg<15, "r15">;

def subreg_8bit : SubRegIndex { let Namespace = "DCPU16"; }

let SubRegIndices = [subreg_8bit] in {
def PCW  : DCPU16RegWithSubregs<0,  "r0",  [PCB]>;
def SPW  : DCPU16RegWithSubregs<1,  "r1",  [SPB]>;
def SRW  : DCPU16RegWithSubregs<2,  "r2",  [SRB]>;
def CGW  : DCPU16RegWithSubregs<3,  "r3",  [CGB]>;
def FPW  : DCPU16RegWithSubregs<4,  "r4",  [FPB]>;
def R5W  : DCPU16RegWithSubregs<5,  "r5",  [R5B]>;
def R6W  : DCPU16RegWithSubregs<6,  "r6",  [R6B]>;
def R7W  : DCPU16RegWithSubregs<7,  "r7",  [R7B]>;
def R8W  : DCPU16RegWithSubregs<8,  "r8",  [R8B]>;
def R9W  : DCPU16RegWithSubregs<9,  "r9",  [R9B]>;
def R10W : DCPU16RegWithSubregs<10, "r10", [R10B]>;
def R11W : DCPU16RegWithSubregs<11, "r11", [R11B]>;
def R12W : DCPU16RegWithSubregs<12, "r12", [R12B]>;
def R13W : DCPU16RegWithSubregs<13, "r13", [R13B]>;
def R14W : DCPU16RegWithSubregs<14, "r14", [R14B]>;
def R15W : DCPU16RegWithSubregs<15, "r15", [R15B]>;
}

def GR8 : RegisterClass<"DCPU16", [i8], 8,
   // Volatile registers
  (add R12B, R13B, R14B, R15B, R11B, R10B, R9B, R8B, R7B, R6B, R5B,
   // Frame pointer, sometimes allocable
   FPB,
   // Volatile, but not allocable
   PCB, SPB, SRB, CGB)>;

def GR16 : RegisterClass<"DCPU16", [i16], 16,
   // Volatile registers
  (add R12W, R13W, R14W, R15W, R11W, R10W, R9W, R8W, R7W, R6W, R5W,
   // Frame pointer, sometimes allocable
   FPW,
   // Volatile, but not allocable
   PCW, SPW, SRW, CGW)>
{
  let SubRegClasses = [(GR8 subreg_8bit)];
}


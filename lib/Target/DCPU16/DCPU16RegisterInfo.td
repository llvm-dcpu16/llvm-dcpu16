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

//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

def PCW  : DCPU16Reg<0,  "r0">;
def SPW  : DCPU16Reg<1,  "C">;
def SRW  : DCPU16Reg<2,  "r2">;
def CGW  : DCPU16Reg<3,  "r3">;
def FPW  : DCPU16Reg<4,  "r4">;
def R1A  : DCPU16Reg<5,  "A">;
def R2B  : DCPU16Reg<6,  "B">;
def R4X  : DCPU16Reg<8,  "X">;
def R5Y  : DCPU16Reg<9,  "Y">;
def R6Z  : DCPU16Reg<0, "Z">;
def R7I  : DCPU16Reg<11, "I">;
def R8J  : DCPU16Reg<12, "J">;

def GR16 : RegisterClass<"DCPU16", [i16], 16,
   // Volatile registers
  (add R8J, R7I, R6Z, R5Y, R4X, R2B, R1A,
   // Frame pointer, sometimes allocable
   FPW,
   // Volatile, but not allocable
   PCW, SPW, SRW, CGW)>;


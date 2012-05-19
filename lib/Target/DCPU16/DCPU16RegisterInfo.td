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

class DCPU16Reg<bits<5> num, string n> : Register<n> {
  field bits<5> Num = num;
  let Namespace = "DCPU16";
}

//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

def A  : DCPU16Reg<0x0,  "A">;
def B  : DCPU16Reg<0x1,  "B">;
def C  : DCPU16Reg<0x2,  "C">;
def X  : DCPU16Reg<0x3,  "X">;
def Y  : DCPU16Reg<0x4,  "Y">;
def Z  : DCPU16Reg<0x5,  "Z">;
def I  : DCPU16Reg<0x6,  "I">;
def J  : DCPU16Reg<0x7,  "J">; // FP if needed

def SP  : DCPU16Reg<0x1b,  "SP">;
def EX  : DCPU16Reg<0x1d,  "EX">;

// Volatile registers
def GR16 : RegisterClass<"DCPU16", [i16], 16,
  (add A,B,C,X,Y,Z,I,J,SP)>;

// Stack pointer register
def SPR16 : RegisterClass<"DCPU16", [i16], 16,
  (add SP)>;

// Overflow register
def EXR16 : RegisterClass<"DCPU16", [i16], 16,
  (add EX)>;

// Both volatile registers and EX
def GEXR16 : RegisterClass<"DCPU16", [i16], 16,
  (add GR16, EXR16)>;

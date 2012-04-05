//==- DCPU16CallingConv.td - Calling Conventions for DCPU16 -*- tablegen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This describes the calling conventions for DCPU16 architecture.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// DCPU16 Return Value Calling Convention
//===----------------------------------------------------------------------===//
def RetCC_DCPU16 : CallingConv<[
  // i8 are returned in registers R4XB, R5YB, R13B, R8JB
  CCIfType<[i8], CCAssignToReg<[R4XB, R5YB, R13B, R8JB]>>,

  // i16 are returned in registers R4X, R5Y, R13, R8J
  CCIfType<[i16], CCAssignToReg<[R4X, R5Y, R13W, R8J]>>
]>;

//===----------------------------------------------------------------------===//
// DCPU16 Argument Calling Conventions
//===----------------------------------------------------------------------===//
def CC_DCPU16 : CallingConv<[
  // Promote i8 arguments to i16.
  CCIfType<[i8], CCPromoteToType<i16>>,

  // The first 4 integer arguments of non-varargs functions are passed in
  // integer registers.
  CCIfNotVarArg<CCIfType<[i16], CCAssignToReg<[R4X, R5Y, R13W, R8J]>>>,

  // Integer values get stored in stack slots that are 2 bytes in
  // size and 2-byte aligned.
  CCIfType<[i16], CCAssignToStack<2, 2>>
]>;

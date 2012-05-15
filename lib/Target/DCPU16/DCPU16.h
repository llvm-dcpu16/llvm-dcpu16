//==-- DCPU16.h - Top-level interface for DCPU16 representation --*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in
// the LLVM DCPU16 backend.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TARGET_DCPU16_H
#define LLVM_TARGET_DCPU16_H

#include "MCTargetDesc/DCPU16MCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace DCPU16CC {
  // DCPU16 specific condition code.
  enum CondCodes {
    COND_B,  // a&b != 0
    COND_C,  // a&b == 0
    COND_E,  // ==
    COND_NE, // !=

    COND_G,  // u>
    COND_A,  // s>
    COND_L,  // u<
    COND_U,  // s<

    // These are pseudo CCs, they get expanded to two IF_ instructions
    COND_GE, // u>=
    COND_AE, // s>=
    COND_LE, // u<=
    COND_UE, // s<=

    COND_INVALID = -1
  };
}

namespace llvm {
  class DCPU16TargetMachine;
  class FunctionPass;
  class formatted_raw_ostream;

  FunctionPass *createDCPU16ISelDag(DCPU16TargetMachine &TM, CodeGenOpt::Level OptLevel);
  FunctionPass *createDCPU16Peephole();
  FunctionPass *createDCPU16DuplicateBranch();

  bool isBR_CC(unsigned Opcode);

} // end namespace llvm;

#endif

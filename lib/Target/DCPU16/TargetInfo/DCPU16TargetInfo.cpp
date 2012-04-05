//===-- DCPU16TargetInfo.cpp - DCPU16 Target Implementation ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "DCPU16.h"
#include "llvm/Module.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target llvm::TheDCPU16Target;

extern "C" void LLVMInitializeDCPU16TargetInfo() { 
  RegisterTarget<Triple::msp430> 
    X(TheDCPU16Target, "msp430", "DCPU16 [experimental]");
}

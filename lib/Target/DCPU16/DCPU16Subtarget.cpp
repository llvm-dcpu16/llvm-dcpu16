//===-- DCPU16Subtarget.cpp - DCPU16 Subtarget Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the DCPU16 specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "DCPU16Subtarget.h"
#include "DCPU16.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "DCPU16GenSubtargetInfo.inc"

using namespace llvm;

void DCPU16Subtarget::anchor() { }

DCPU16Subtarget::DCPU16Subtarget(const std::string &TT,
                                 const std::string &CPU,
                                 const std::string &FS) :
  DCPU16GenSubtargetInfo(TT, CPU, FS) {
  std::string CPUName = "generic";

  // Parse features string.
  ParseSubtargetFeatures(CPUName, FS);
}

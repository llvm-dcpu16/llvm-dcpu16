//===- DCPU16MachineFuctionInfo.h - DCPU16 machine function info -*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares DCPU16-specific per-machine-function information.
//
//===----------------------------------------------------------------------===//

#ifndef DCPU16MACHINEFUNCTIONINFO_H
#define DCPU16MACHINEFUNCTIONINFO_H

#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {

/// DCPU16MachineFunctionInfo - This class is derived from MachineFunction and
/// contains private DCPU16 target-specific information for each MachineFunction.
class DCPU16MachineFunctionInfo : public MachineFunctionInfo {
  virtual void anchor();

  /// CalleeSavedFrameSize - Size of the callee-saved register portion of the
  /// stack frame in bytes.
  unsigned CalleeSavedFrameSize;

  /// ReturnAddrIndex - FrameIndex for return slot.
  int ReturnAddrIndex;

public:
  DCPU16MachineFunctionInfo() : CalleeSavedFrameSize(0) {}

  explicit DCPU16MachineFunctionInfo(MachineFunction &MF)
    : CalleeSavedFrameSize(0), ReturnAddrIndex(0) {}

  unsigned getCalleeSavedFrameSize() const { return CalleeSavedFrameSize; }
  void setCalleeSavedFrameSize(unsigned bytes) { CalleeSavedFrameSize = bytes; }

  int getRAIndex() const { return ReturnAddrIndex; }
  void setRAIndex(int Index) { ReturnAddrIndex = Index; }
};

} // End llvm namespace

#endif

//==- DCPU16FrameLowering.h - Define frame lowering for DCPU16 --*- C++ -*--==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//
//===----------------------------------------------------------------------===//

#ifndef DCPU16_FRAMEINFO_H
#define DCPU16_FRAMEINFO_H

#include "DCPU16.h"
#include "DCPU16Subtarget.h"
#include "llvm/Target/TargetFrameLowering.h"

namespace llvm {
  class DCPU16Subtarget;

class DCPU16FrameLowering : public TargetFrameLowering {
protected:
  const DCPU16Subtarget &STI;

public:
  explicit DCPU16FrameLowering(const DCPU16Subtarget &sti)
    : TargetFrameLowering(TargetFrameLowering::StackGrowsDown, 1, -1), STI(sti) {
  }

  /// emitProlog/emitEpilog - These methods insert prolog and epilog code into
  /// the function.
  void emitPrologue(MachineFunction &MF) const;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const;

  bool spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI,
                                 const std::vector<CalleeSavedInfo> &CSI,
                                 const TargetRegisterInfo *TRI) const;
  bool restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                                   MachineBasicBlock::iterator MI,
                                   const std::vector<CalleeSavedInfo> &CSI,
                                   const TargetRegisterInfo *TRI) const;

  bool hasFP(const MachineFunction &MF) const;
  bool hasReservedCallFrame(const MachineFunction &MF) const;

  void processFunctionBeforeFrameFinalized(MachineFunction &MF) const;
};

} // End llvm namespace

#endif

//===-- DCPU16TargetMachine.h - Define TargetMachine for DCPU16 -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the DCPU16 specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//


#ifndef LLVM_TARGET_DCPU16_TARGETMACHINE_H
#define LLVM_TARGET_DCPU16_TARGETMACHINE_H

#include "DCPU16InstrInfo.h"
#include "DCPU16ISelLowering.h"
#include "DCPU16FrameLowering.h"
#include "DCPU16SelectionDAGInfo.h"
#include "DCPU16RegisterInfo.h"
#include "DCPU16Subtarget.h"
#include "llvm/Target/TargetData.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

/// DCPU16TargetMachine
///
class DCPU16TargetMachine : public LLVMTargetMachine {
  DCPU16Subtarget        Subtarget;
  const TargetData       DataLayout;       // Calculates type size & alignment
  DCPU16InstrInfo        InstrInfo;
  DCPU16TargetLowering   TLInfo;
  DCPU16SelectionDAGInfo TSInfo;
  DCPU16FrameLowering    FrameLowering;

public:
  DCPU16TargetMachine(const Target &T, StringRef TT,
                      StringRef CPU, StringRef FS, const TargetOptions &Options,
                      Reloc::Model RM, CodeModel::Model CM,
                      CodeGenOpt::Level OL);

  virtual const TargetFrameLowering *getFrameLowering() const {
    return &FrameLowering;
  }
  virtual const DCPU16InstrInfo *getInstrInfo() const  { return &InstrInfo; }
  virtual const TargetData *getTargetData() const     { return &DataLayout;}
  virtual const DCPU16Subtarget *getSubtargetImpl() const { return &Subtarget; }

  virtual const TargetRegisterInfo *getRegisterInfo() const {
    return &InstrInfo.getRegisterInfo();
  }

  virtual const DCPU16TargetLowering *getTargetLowering() const {
    return &TLInfo;
  }

  virtual const DCPU16SelectionDAGInfo* getSelectionDAGInfo() const {
    return &TSInfo;
  }

  virtual TargetPassConfig *createPassConfig(PassManagerBase &PM);
}; // DCPU16TargetMachine.

} // end namespace llvm

#endif // LLVM_TARGET_DCPU16_TARGETMACHINE_H

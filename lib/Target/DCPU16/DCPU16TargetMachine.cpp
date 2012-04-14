//===-- DCPU16TargetMachine.cpp - Define TargetMachine for DCPU16 ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Top-level implementation for the DCPU16 target.
//
//===----------------------------------------------------------------------===//

#include "DCPU16TargetMachine.h"
#include "DCPU16.h"
#include "MCTargetDesc/DCPU16MCAsmInfo.h"
#include "llvm/PassManager.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

extern "C" void LLVMInitializeDCPU16Target() {
  // Register the target.
  RegisterTargetMachine<DCPU16TargetMachine> X(TheDCPU16Target);
}

DCPU16TargetMachine::DCPU16TargetMachine(const Target &T,
                                         StringRef TT,
                                         StringRef CPU,
                                         StringRef FS,
                                         const TargetOptions &Options,
                                         Reloc::Model RM, CodeModel::Model CM,
                                         CodeGenOpt::Level OL)
  : LLVMTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL),
    Subtarget(TT, CPU, FS),
    // FIXME: Check TargetData string.
    DataLayout("e-p:16:16:16-i16:16:16-i32:16:32-n16"),
    InstrInfo(*this), TLInfo(*this), TSInfo(*this),
    FrameLowering(Subtarget) { }

namespace {
/// DCPU16 Code Generator Pass Configuration Options.
class DCPU16PassConfig : public TargetPassConfig {
public:
  DCPU16PassConfig(DCPU16TargetMachine *TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM) {}

  DCPU16TargetMachine &getDCPU16TargetMachine() const {
    return getTM<DCPU16TargetMachine>();
  }

  virtual bool addInstSelector();
};
} // namespace

TargetPassConfig *DCPU16TargetMachine::createPassConfig(PassManagerBase &PM) {
  return new DCPU16PassConfig(this, PM);
}

bool DCPU16PassConfig::addInstSelector() {
  // Install an instruction selector.
  PM.add(createDCPU16ISelDag(getDCPU16TargetMachine(), getOptLevel()));
  return false;
}

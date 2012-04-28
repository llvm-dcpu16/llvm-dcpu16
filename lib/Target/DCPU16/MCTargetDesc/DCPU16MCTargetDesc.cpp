//===-- DCPU16MCTargetDesc.cpp - DCPU16 Target Descriptions ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides DCPU16 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "DCPU16MCTargetDesc.h"
#include "DCPU16MCAsmInfo.h"
#include "InstPrinter/DCPU16InstPrinter.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#include "DCPU16GenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "DCPU16GenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "DCPU16GenRegisterInfo.inc"

using namespace llvm;

static MCInstrInfo *createDCPU16MCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitDCPU16MCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createDCPU16MCRegisterInfo(StringRef TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitDCPU16MCRegisterInfo(X, DCPU16::A);
  return X;
}

static MCSubtargetInfo *createDCPU16MCSubtargetInfo(StringRef TT, StringRef CPU,
                                                    StringRef FS) {
  MCSubtargetInfo *X = new MCSubtargetInfo();
  InitDCPU16MCSubtargetInfo(X, TT, CPU, FS);
  return X;
}

static MCCodeGenInfo *createDCPU16MCCodeGenInfo(StringRef TT, Reloc::Model RM,
                                                CodeModel::Model CM,
                                                CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  X->InitMCCodeGenInfo(RM, CM, OL);
  return X;
}

static MCInstPrinter *createDCPU16MCInstPrinter(const Target &T,
                                                unsigned SyntaxVariant,
                                                const MCAsmInfo &MAI,
                                                const MCInstrInfo &MII,
                                                const MCRegisterInfo &MRI,
                                                const MCSubtargetInfo &STI) {
  if (SyntaxVariant == 0)
    return new DCPU16InstPrinter(MAI, MII, MRI);
  return 0;
}

extern "C" void LLVMInitializeDCPU16TargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfo<DCPU16MCAsmInfo> X(TheDCPU16Target);

  // Register the MC codegen info.
  TargetRegistry::RegisterMCCodeGenInfo(TheDCPU16Target,
                                        createDCPU16MCCodeGenInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheDCPU16Target, createDCPU16MCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheDCPU16Target,
                                    createDCPU16MCRegisterInfo);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheDCPU16Target,
                                          createDCPU16MCSubtargetInfo);

  // Register the MCInstPrinter.
  TargetRegistry::RegisterMCInstPrinter(TheDCPU16Target,
                                        createDCPU16MCInstPrinter);
}

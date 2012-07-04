//===-- MipsRegisterInfo.cpp - MIPS Register Information -== --------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the MIPS implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "mips-reg-info"

#include "MipsRegisterInfo.h"
#include "Mips.h"
#include "MipsAnalyzeImmediate.h"
#include "MipsInstrInfo.h"
#include "MipsSubtarget.h"
#include "MipsMachineFunction.h"
#include "llvm/Constants.h"
#include "llvm/DebugInfo.h"
#include "llvm/Type.h"
#include "llvm/Function.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/STLExtras.h"

#define GET_REGINFO_TARGET_DESC
#include "MipsGenRegisterInfo.inc"

using namespace llvm;

MipsRegisterInfo::MipsRegisterInfo(const MipsSubtarget &ST,
                                   const TargetInstrInfo &tii)
  : MipsGenRegisterInfo(Mips::RA), Subtarget(ST), TII(tii) {}

unsigned MipsRegisterInfo::getPICCallReg() { return Mips::T9; }

//===----------------------------------------------------------------------===//
// Callee Saved Registers methods
//===----------------------------------------------------------------------===//

/// Mips Callee Saved Registers
const uint16_t* MipsRegisterInfo::
getCalleeSavedRegs(const MachineFunction *MF) const {
  if (Subtarget.isSingleFloat())
    return CSR_SingleFloatOnly_SaveList;
  else if (!Subtarget.hasMips64())
    return CSR_O32_SaveList;
  else if (Subtarget.isABI_N32())
    return CSR_N32_SaveList;

  assert(Subtarget.isABI_N64());
  return CSR_N64_SaveList;
}

const uint32_t*
MipsRegisterInfo::getCallPreservedMask(CallingConv::ID) const {
  if (Subtarget.isSingleFloat())
    return CSR_SingleFloatOnly_RegMask;
  else if (!Subtarget.hasMips64())
    return CSR_O32_RegMask;
  else if (Subtarget.isABI_N32())
    return CSR_N32_RegMask;

  assert(Subtarget.isABI_N64());
  return CSR_N64_RegMask;
}

BitVector MipsRegisterInfo::
getReservedRegs(const MachineFunction &MF) const {
  static const uint16_t ReservedCPURegs[] = {
    Mips::ZERO, Mips::AT, Mips::K0, Mips::K1,
    Mips::SP, Mips::RA
  };

  static const uint16_t ReservedCPU64Regs[] = {
    Mips::ZERO_64, Mips::AT_64, Mips::K0_64, Mips::K1_64,
    Mips::SP_64, Mips::RA_64
  };

  BitVector Reserved(getNumRegs());
  typedef TargetRegisterClass::const_iterator RegIter;

  for (unsigned I = 0; I < array_lengthof(ReservedCPURegs); ++I)
    Reserved.set(ReservedCPURegs[I]);

  if (Subtarget.hasMips64()) {
    for (unsigned I = 0; I < array_lengthof(ReservedCPU64Regs); ++I)
      Reserved.set(ReservedCPU64Regs[I]);

    // Reserve all registers in AFGR64.
    for (RegIter Reg = Mips::AFGR64RegClass.begin(),
         EReg = Mips::AFGR64RegClass.end(); Reg != EReg; ++Reg)
      Reserved.set(*Reg);
  } else {
    // Reserve all registers in CPU64Regs & FGR64.
    for (RegIter Reg = Mips::CPU64RegsRegClass.begin(),
         EReg = Mips::CPU64RegsRegClass.end(); Reg != EReg; ++Reg)
      Reserved.set(*Reg);

    for (RegIter Reg = Mips::FGR64RegClass.begin(),
         EReg = Mips::FGR64RegClass.end(); Reg != EReg; ++Reg)
      Reserved.set(*Reg);
  }

  // Reserve FP if this function should have a dedicated frame pointer register.
  if (MF.getTarget().getFrameLowering()->hasFP(MF)) {
    Reserved.set(Mips::FP);
    Reserved.set(Mips::FP_64);
  }

  // Reserve hardware registers.
  Reserved.set(Mips::HWR29);
  Reserved.set(Mips::HWR29_64);

  return Reserved;
}

bool
MipsRegisterInfo::requiresRegisterScavenging(const MachineFunction &MF) const {
  return true;
}

bool
MipsRegisterInfo::trackLivenessAfterRegAlloc(const MachineFunction &MF) const {
  return true;
}

// This function eliminate ADJCALLSTACKDOWN,
// ADJCALLSTACKUP pseudo instructions
void MipsRegisterInfo::
eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator I) const {
  // Simply discard ADJCALLSTACKDOWN, ADJCALLSTACKUP instructions.
  MBB.erase(I);
}

// FrameIndex represent objects inside a abstract stack.
// We must replace FrameIndex with an stack/frame pointer
// direct reference.
void MipsRegisterInfo::
eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj,
                    RegScavenger *RS) const {
  MachineInstr &MI = *II;
  MachineFunction &MF = *MI.getParent()->getParent();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  MipsFunctionInfo *MipsFI = MF.getInfo<MipsFunctionInfo>();

  unsigned i = 0;
  while (!MI.getOperand(i).isFI()) {
    ++i;
    assert(i < MI.getNumOperands() &&
           "Instr doesn't have FrameIndex operand!");
  }

  DEBUG(errs() << "\nFunction : " << MF.getFunction()->getName() << "\n";
        errs() << "<--------->\n" << MI);

  int FrameIndex = MI.getOperand(i).getIndex();
  uint64_t stackSize = MF.getFrameInfo()->getStackSize();
  int64_t spOffset = MF.getFrameInfo()->getObjectOffset(FrameIndex);

  DEBUG(errs() << "FrameIndex : " << FrameIndex << "\n"
               << "spOffset   : " << spOffset << "\n"
               << "stackSize  : " << stackSize << "\n");

  const std::vector<CalleeSavedInfo> &CSI = MFI->getCalleeSavedInfo();
  int MinCSFI = 0;
  int MaxCSFI = -1;

  if (CSI.size()) {
    MinCSFI = CSI[0].getFrameIdx();
    MaxCSFI = CSI[CSI.size() - 1].getFrameIdx();
  }

  // The following stack frame objects are always referenced relative to $sp:
  //  1. Outgoing arguments.
  //  2. Pointer to dynamically allocated stack space.
  //  3. Locations for callee-saved registers.
  // Everything else is referenced relative to whatever register
  // getFrameRegister() returns.
  unsigned FrameReg;

  if (MipsFI->isOutArgFI(FrameIndex) || MipsFI->isDynAllocFI(FrameIndex) ||
      (FrameIndex >= MinCSFI && FrameIndex <= MaxCSFI))
    FrameReg = Subtarget.isABI_N64() ? Mips::SP_64 : Mips::SP;
  else
    FrameReg = getFrameRegister(MF);

  // Calculate final offset.
  // - There is no need to change the offset if the frame object is one of the
  //   following: an outgoing argument, pointer to a dynamically allocated
  //   stack space or a $gp restore location,
  // - If the frame object is any of the following, its offset must be adjusted
  //   by adding the size of the stack:
  //   incoming argument, callee-saved register location or local variable.
  int64_t Offset;

  if (MipsFI->isOutArgFI(FrameIndex) || MipsFI->isDynAllocFI(FrameIndex) ||
      MipsFI->isGlobalRegFI(FrameIndex))
    Offset = spOffset;
  else
    Offset = spOffset + (int64_t)stackSize;

  Offset    += MI.getOperand(i+1).getImm();

  DEBUG(errs() << "Offset     : " << Offset << "\n" << "<--------->\n");

  // If MI is not a debug value, make sure Offset fits in the 16-bit immediate
  // field.
  if (!MI.isDebugValue() && !isInt<16>(Offset)) {
    MachineBasicBlock &MBB = *MI.getParent();
    DebugLoc DL = II->getDebugLoc();
    unsigned ADDu = Subtarget.isABI_N64() ? Mips::DADDu : Mips::ADDu;
    unsigned ATReg = Subtarget.isABI_N64() ? Mips::AT_64 : Mips::AT;
    MipsAnalyzeImmediate::Inst LastInst(0, 0);

    MipsFI->setEmitNOAT();
    Mips::loadImmediate(Offset, Subtarget.isABI_N64(), TII, MBB, II, DL, true,
                        &LastInst);
    BuildMI(MBB, II, DL, TII.get(ADDu), ATReg).addReg(FrameReg).addReg(ATReg);

    FrameReg = ATReg;
    Offset = SignExtend64<16>(LastInst.ImmOpnd);
  }

  MI.getOperand(i).ChangeToRegister(FrameReg, false);
  MI.getOperand(i+1).ChangeToImmediate(Offset);
}

unsigned MipsRegisterInfo::
getFrameRegister(const MachineFunction &MF) const {
  const TargetFrameLowering *TFI = MF.getTarget().getFrameLowering();
  bool IsN64 = Subtarget.isABI_N64();

  return TFI->hasFP(MF) ? (IsN64 ? Mips::FP_64 : Mips::FP) :
                          (IsN64 ? Mips::SP_64 : Mips::SP);
}

unsigned MipsRegisterInfo::
getEHExceptionRegister() const {
  llvm_unreachable("What is the exception register");
}

unsigned MipsRegisterInfo::
getEHHandlerRegister() const {
  llvm_unreachable("What is the exception handler register");
}

//===-- DCPU16FrameLowering.cpp - DCPU16 Frame Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the DCPU16 implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "DCPU16FrameLowering.h"
#include "DCPU16InstrInfo.h"
#include "DCPU16MachineFunctionInfo.h"
#include "llvm/Function.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Target/TargetData.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

bool DCPU16FrameLowering::hasFP(const MachineFunction &MF) const {
  return false;
}

bool DCPU16FrameLowering::hasReservedCallFrame(const MachineFunction &MF) const {
  return !MF.getFrameInfo()->hasVarSizedObjects();
}

void DCPU16FrameLowering::emitPrologue(MachineFunction &MF) const {
  MachineBasicBlock &MBB = MF.front();   // Prolog goes in entry BB
  MachineFrameInfo *MFI = MF.getFrameInfo();
  DCPU16MachineFunctionInfo *DCPU16FI = MF.getInfo<DCPU16MachineFunctionInfo>();
  const DCPU16InstrInfo &TII =
    *static_cast<const DCPU16InstrInfo*>(MF.getTarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc DL = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  // Get the number of bytes to allocate from the FrameInfo.
  uint64_t StackSize = MFI->getStackSize();

  uint64_t NumBytes = 0;
  NumBytes = StackSize - DCPU16FI->getCalleeSavedFrameSize();

  // Skip the callee-saved push instructions.
  while (MBBI != MBB.end() && (MBBI->getOpcode() == DCPU16::PUSH16r))
    ++MBBI;

  if (MBBI != MBB.end())
    DL = MBBI->getDebugLoc();

  if (NumBytes) { // adjust stack pointer: RC -= numbytes
    // If there is an SUB16ri of RC immediately before this instruction, merge
    // the two.
    //NumBytes -= mergeSPUpdates(MBB, MBBI, true);
    // If there is an ADD16ri or SUB16ri of RC immediately after this
    // instruction, merge the two instructions.
    // mergeSPUpdatesDown(MBB, MBBI, &NumBytes);

    if (NumBytes) {
      MachineInstr *MI =
        BuildMI(MBB, MBBI, DL, TII.get(DCPU16::SUB16ri), DCPU16::RC)
        .addReg(DCPU16::RC).addImm(NumBytes);
      // TODO: STILL NEEDED? Old comment: The SRW implicit def is dead.
      MI->getOperand(3).setIsDead();
    }
  }
}

void DCPU16FrameLowering::emitEpilogue(MachineFunction &MF,
                                       MachineBasicBlock &MBB) const {
  const MachineFrameInfo *MFI = MF.getFrameInfo();
  DCPU16MachineFunctionInfo *DCPU16FI = MF.getInfo<DCPU16MachineFunctionInfo>();
  const DCPU16InstrInfo &TII =
    *static_cast<const DCPU16InstrInfo*>(MF.getTarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  unsigned RetOpcode = MBBI->getOpcode();
  DebugLoc DL = MBBI->getDebugLoc();

  if (RetOpcode != DCPU16::RET)
    llvm_unreachable("Can only insert epilog into returning blocks");

  // Get the number of bytes to allocate from the FrameInfo
  uint64_t StackSize = MFI->getStackSize();
  unsigned CSSize = DCPU16FI->getCalleeSavedFrameSize();

  uint64_t NumBytes = 0;
  NumBytes = StackSize - CSSize;

  // Skip the callee-saved pop instructions.
  while (MBBI != MBB.begin()) {
    MachineBasicBlock::iterator PI = prior(MBBI);
    unsigned Opc = PI->getOpcode();
    if (Opc != DCPU16::POP16r && !PI->isTerminator())
      break;
    --MBBI;
  }

  DL = MBBI->getDebugLoc();

  // If there is an ADD16ri or SUB16ri of RC immediately before this
  // instruction, merge the two instructions.
  //if (NumBytes)
  //  mergeSPUpdatesUp(MBB, MBBI, StackPtr, &NumBytes);

  // adjust stack pointer back: RC += numbytes
  if (NumBytes) {
    MachineInstr *MI =
      BuildMI(MBB, MBBI, DL, TII.get(DCPU16::ADD16ri), DCPU16::RC)
      .addReg(DCPU16::RC).addImm(NumBytes);
    // TODO: STILL NEEDED? Old comment: The SRW implicit def is dead.
    MI->getOperand(3).setIsDead();
  }
}

// FIXME: Can we eleminate these in favour of generic code?
bool
DCPU16FrameLowering::spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                           MachineBasicBlock::iterator MI,
                                        const std::vector<CalleeSavedInfo> &CSI,
                                        const TargetRegisterInfo *TRI) const {
  if (CSI.empty())
    return false;

  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();

  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getTarget().getInstrInfo();
  DCPU16MachineFunctionInfo *MFI = MF.getInfo<DCPU16MachineFunctionInfo>();
  MFI->setCalleeSavedFrameSize(CSI.size() * 2);

  for (unsigned i = CSI.size(); i != 0; --i) {
    unsigned Reg = CSI[i-1].getReg();
    // Add the callee-saved register as live-in. It's killed at the spill.
    MBB.addLiveIn(Reg);
    BuildMI(MBB, MI, DL, TII.get(DCPU16::PUSH16r))
      .addReg(Reg, RegState::Kill);
  }
  return true;
}

bool
DCPU16FrameLowering::restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                                                 MachineBasicBlock::iterator MI,
                                        const std::vector<CalleeSavedInfo> &CSI,
                                        const TargetRegisterInfo *TRI) const {
  if (CSI.empty())
    return false;

  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();

  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getTarget().getInstrInfo();

  for (unsigned i = 0, e = CSI.size(); i != e; ++i)
    BuildMI(MBB, MI, DL, TII.get(DCPU16::POP16r), CSI[i].getReg());

  return true;
}

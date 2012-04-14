//===-- DCPU16InstrInfo.cpp - DCPU16 Instruction Information --------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the DCPU16 implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "DCPU16InstrInfo.h"
#include "DCPU16.h"
#include "DCPU16MachineFunctionInfo.h"
#include "DCPU16TargetMachine.h"
#include "llvm/Function.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_CTOR
#include "DCPU16GenInstrInfo.inc"

using namespace llvm;

DCPU16InstrInfo::DCPU16InstrInfo(DCPU16TargetMachine &tm)
  : DCPU16GenInstrInfo(DCPU16::ADJCALLSTACKDOWN, DCPU16::ADJCALLSTACKUP),
    RI(tm, *this), TM(tm) {}

void DCPU16InstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                          MachineBasicBlock::iterator MI,
                                    unsigned SrcReg, bool isKill, int FrameIdx,
                                          const TargetRegisterClass *RC,
                                          const TargetRegisterInfo *TRI) const {
  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();

  MachineMemOperand *MMO =
    MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(FrameIdx),
                            MachineMemOperand::MOStore,
                            MFI.getObjectSize(FrameIdx),
                            MFI.getObjectAlignment(FrameIdx));

  if (RC == &DCPU16::GR16RegClass)
    BuildMI(MBB, MI, DL, get(DCPU16::MOV16mr))
      .addFrameIndex(FrameIdx).addImm(0)
      .addReg(SrcReg, getKillRegState(isKill)).addMemOperand(MMO);
  else
    llvm_unreachable("Cannot store this register to stack slot!");
}

void DCPU16InstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                           MachineBasicBlock::iterator MI,
                                           unsigned DestReg, int FrameIdx,
                                           const TargetRegisterClass *RC,
                                           const TargetRegisterInfo *TRI) const{
  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();

  MachineMemOperand *MMO =
    MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(FrameIdx),
                            MachineMemOperand::MOLoad,
                            MFI.getObjectSize(FrameIdx),
                            MFI.getObjectAlignment(FrameIdx));

  if (RC == &DCPU16::GR16RegClass)
    BuildMI(MBB, MI, DL, get(DCPU16::MOV16rm))
      .addReg(DestReg).addFrameIndex(FrameIdx).addImm(0).addMemOperand(MMO);
  else
    llvm_unreachable("Cannot store this register to stack slot!");
}

void DCPU16InstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                  MachineBasicBlock::iterator I, DebugLoc DL,
                                  unsigned DestReg, unsigned SrcReg,
                                  bool KillSrc) const {

  // An interesting aspect of DCPU16 is that all the registers,
  // including PC, SP and O are valid SET arguments. So, it's
  // legal to say SET PC, O; It just usually does not make sense.
  unsigned Opc = DCPU16::MOV16rr;

  BuildMI(MBB, I, DL, get(Opc), DestReg)
    .addReg(SrcReg, getKillRegState(KillSrc));
}

unsigned DCPU16InstrInfo::RemoveBranch(MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugValue())
      continue;
    if (I->getOpcode() != DCPU16::JMP &&
        I->getOpcode() != DCPU16::BR_CC &&
        I->getOpcode() != DCPU16::Br &&
        I->getOpcode() != DCPU16::Bm)
      break;
    // Remove the branch.
    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}

bool DCPU16InstrInfo::
ReverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const {
  assert(Cond.size() == 3 && "Invalid BR_CC condition!");

  DCPU16CC::CondCodes CC = static_cast<DCPU16CC::CondCodes>(Cond[0].getImm());

  switch (CC) {
  default: llvm_unreachable("Invalid branch condition!");
  case DCPU16CC::COND_E:
    CC = DCPU16CC::COND_NE;
    break;
  case DCPU16CC::COND_NE:
    CC = DCPU16CC::COND_E;
    break;
  case DCPU16CC::COND_G:
    std::swap(Cond[1], Cond[2]);
    CC = DCPU16CC::COND_GE;
    break;
  case DCPU16CC::COND_GE:
    std::swap(Cond[1], Cond[2]);
    CC = DCPU16CC::COND_G;
    break;
  case DCPU16CC::COND_B:
    return true;
  }

  Cond[0].setImm(CC);
  return false;
}

bool DCPU16InstrInfo::isUnpredicatedTerminator(const MachineInstr *MI) const {
  if (!MI->isTerminator()) return false;

  // Conditional branch is a special case.
  if (MI->isBranch() && !MI->isBarrier())
    return true;
  if (!MI->isPredicable())
    return true;
  return !isPredicated(MI);
}

bool DCPU16InstrInfo::AnalyzeBranch(MachineBasicBlock &MBB,
                                    MachineBasicBlock *&TBB,
                                    MachineBasicBlock *&FBB,
                                    SmallVectorImpl<MachineOperand> &Cond,
                                    bool AllowModify) const {
  // Start from the bottom of the block and work up, examining the
  // terminator instructions.
  MachineBasicBlock::iterator I = MBB.end();
  while (I != MBB.begin()) {
    --I;
    if (I->isDebugValue())
      continue;

    // Working from the bottom, when we see a non-terminator
    // instruction, we're done.
    if (!isUnpredicatedTerminator(I))
      break;

    // A terminator that isn't a branch can't easily be handled
    // by this analysis.
    if (!I->isBranch())
      return true;

    // Cannot handle indirect branches.
    if (I->getOpcode() == DCPU16::Br ||
        I->getOpcode() == DCPU16::Bm)
      return true;

    // Handle unconditional branches.
    if (I->getOpcode() == DCPU16::JMP) {
      if (!AllowModify) {
        TBB = I->getOperand(0).getMBB();
        continue;
      }

      // If the block has any instructions after a JMP, delete them.
      while (llvm::next(I) != MBB.end())
        llvm::next(I)->eraseFromParent();
      Cond.clear();
      FBB = 0;

      // Delete the JMP if it's equivalent to a fall-through.
      if (MBB.isLayoutSuccessor(I->getOperand(0).getMBB())) {
        TBB = 0;
        I->eraseFromParent();
        I = MBB.end();
        continue;
      }

      // TBB is used to indicate the unconditinal destination.
      TBB = I->getOperand(0).getMBB();
      continue;
    }

    // Handle conditional branches.
    assert(I->getOpcode() == DCPU16::BR_CC && "Invalid conditional branch");
    DCPU16CC::CondCodes BranchCode =
      static_cast<DCPU16CC::CondCodes>(I->getOperand(0).getImm());
    if (BranchCode == DCPU16CC::COND_INVALID)
      return true;  // Can't handle weird stuff.

    MachineOperand LHS = I->getOperand(1);
    MachineOperand RHS = I->getOperand(2);

    // Working from the bottom, handle the first conditional branch.
    if (Cond.empty()) {
      FBB = TBB;
      TBB = I->getOperand(3).getMBB();
      Cond.push_back(MachineOperand::CreateImm(BranchCode));
      Cond.push_back(LHS);
      Cond.push_back(RHS);
      continue;
    }

    assert(Cond.size() == 3);
    assert(TBB);

    // Is it a >= ?
    if ((BranchCode == DCPU16CC::COND_E)
        && (((DCPU16CC::CondCodes) Cond[0].getImm()) == DCPU16CC::COND_G)
        && (TBB == I->getOperand(3).getMBB())
        && (((Cond[1].getReg() == LHS.getReg()) && (Cond[2].getReg() == RHS.getReg()))
          || ((Cond[1].getReg() == RHS.getReg()) && (Cond[2].getReg() == LHS.getReg())))) {

      Cond[0] = MachineOperand::CreateImm(DCPU16CC::COND_GE);
    }
    break;
  }

  return false;
}

unsigned
DCPU16InstrInfo::InsertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                              MachineBasicBlock *FBB,
                              const SmallVectorImpl<MachineOperand> &Cond,
                              DebugLoc DL) const {
  // Shouldn't be a fall through.
  assert(TBB && "InsertBranch must not be told to insert a fallthrough");
  assert((Cond.size() == 3 || Cond.size() == 0) &&
         "DCPU16 branch conditions have three components!");

  if (Cond.empty()) {
    // Unconditional branch?
    assert(!FBB && "Unconditional branch with multiple successors!");
    BuildMI(&MBB, DL, get(DCPU16::JMP)).addMBB(TBB);
    return 1;
  }

  // Conditional branch.
  unsigned Count = 0;
  DCPU16CC::CondCodes CC = (DCPU16CC::CondCodes) Cond[0].getImm();
  MachineOperand LHS = Cond[1];
  MachineOperand RHS = Cond[2];
  // Is it a >= ?
  if (CC == DCPU16CC::COND_GE) {
    if (FBB) {
      // Switch targets around to produce shorter code
      std::swap(TBB, FBB);
      std::swap(LHS, RHS);
    } else {
      BuildMI(&MBB, DL, get(DCPU16::BR_CC))
        .addImm(DCPU16CC::COND_E)
        .addOperand(LHS).addOperand(RHS)
        .addMBB(TBB);
      ++Count;
    }
    CC = DCPU16CC::COND_G;
  }
  BuildMI(&MBB, DL, get(DCPU16::BR_CC))
    .addImm(CC)
    .addOperand(LHS).addOperand(RHS)
    .addMBB(TBB);
  ++Count;

  if (FBB) {
    // Two-way Conditional branch. Insert the second branch.
    BuildMI(&MBB, DL, get(DCPU16::JMP)).addMBB(FBB);
    ++Count;
  }
  return Count;
}

/// GetInstSize - Return the number of bytes of code the specified
/// instruction may be.  This returns the maximum number of bytes.
///
unsigned DCPU16InstrInfo::GetInstSizeInBytes(const MachineInstr *MI) const {
  const MCInstrDesc &Desc = MI->getDesc();

  switch (Desc.TSFlags & DCPU16II::SizeMask) {
  default:
    switch (Desc.getOpcode()) {
    default: llvm_unreachable("Unknown instruction size!");
    case TargetOpcode::PROLOG_LABEL:
    case TargetOpcode::EH_LABEL:
    case TargetOpcode::IMPLICIT_DEF:
    case TargetOpcode::KILL:
    case TargetOpcode::DBG_VALUE:
      return 0;
    case TargetOpcode::INLINEASM: {
      const MachineFunction *MF = MI->getParent()->getParent();
      const TargetInstrInfo &TII = *MF->getTarget().getInstrInfo();
      return TII.getInlineAsmLength(MI->getOperand(0).getSymbolName(),
                                    *MF->getTarget().getMCAsmInfo());
    }
    }
  case DCPU16II::Size2Bytes:
    return 2;
  case DCPU16II::Size4Bytes:
    return 4;
  case DCPU16II::Size6Bytes:
    return 6;
  }
}

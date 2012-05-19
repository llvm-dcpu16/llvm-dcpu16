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

  if (RC == &DCPU16::GR16RegClass || RC == &DCPU16::GEXR16RegClass)
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

  if (RC == &DCPU16::GR16RegClass || RC == &DCPU16::GEXR16RegClass)
    BuildMI(MBB, MI, DL, get(DCPU16::MOV16rm), DestReg)
      .addFrameIndex(FrameIdx).addImm(0).addMemOperand(MMO);
  else
    llvm_unreachable("Cannot store this register to stack slot!");
}

unsigned DCPU16InstrInfo::isLoadFromStackSlot(const MachineInstr *MI,
                                              int &FrameIndex) const {
  if (MI->getOpcode() == DCPU16::MOV16rm) {
    if (MI->getOperand(1).isFI()) {
      // MOV reg, [SP+idx]
      // operand 0 is dest reg, 1 is frame index, 2 immediate 0
      FrameIndex = MI->getOperand(1).getIndex();
      return MI->getOperand(0).getReg();
    }
  }
  return 0;
}

unsigned DCPU16InstrInfo::isStoreToStackSlot(const MachineInstr *MI,
                                            int &FrameIndex) const {
  if (MI->getOpcode() == DCPU16::MOV16mr) {
    if (MI->getOperand(0).isFI()) {
      // MOV [SP+idx], reg
      // operand 0 is frame index, 1 is immediate 0, 2 is register
      FrameIndex = MI->getOperand(0).getIndex();
      return MI->getOperand(2).getReg();
    }
  }
  return 0;
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

static bool isBR_CC(unsigned Opcode) {
  switch (Opcode) {
    default: return false;
    case DCPU16::BR_CCrr:
    case DCPU16::BR_CCri:
    case DCPU16::BR_CCir:
    case DCPU16::BR_CCii:
      return true;
  }
}

unsigned DCPU16InstrInfo::RemoveBranch(MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugValue())
      continue;
    if (I->getOpcode() != DCPU16::JMP &&
        !isBR_CC(I->getOpcode()) &&
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
  assert(Cond.size() == 4 && "Invalid BR_CC condition!");

  DCPU16CC::CondCodes CC = static_cast<DCPU16CC::CondCodes>(Cond[1].getImm());

  switch (CC) {
  default: llvm_unreachable("Invalid branch condition!");
  case DCPU16CC::COND_B:
    CC = DCPU16CC::COND_C;
    break;
  case DCPU16CC::COND_C:
    CC = DCPU16CC::COND_B;
    break;
  case DCPU16CC::COND_E:
    CC = DCPU16CC::COND_NE;
    break;
  case DCPU16CC::COND_NE:
    CC = DCPU16CC::COND_E;
    break;
  case DCPU16CC::COND_G:
    CC = DCPU16CC::COND_LE;
    break;
  case DCPU16CC::COND_A:
    CC = DCPU16CC::COND_UE;
    break;
  case DCPU16CC::COND_L:
    CC = DCPU16CC::COND_GE;
    break;
  case DCPU16CC::COND_U:
    CC = DCPU16CC::COND_AE;
    break;
  case DCPU16CC::COND_GE:
    CC = DCPU16CC::COND_L;
    break;
  case DCPU16CC::COND_AE:
    CC = DCPU16CC::COND_U;
    break;
  case DCPU16CC::COND_LE:
    CC = DCPU16CC::COND_G;
    break;
  case DCPU16CC::COND_UE:
    CC = DCPU16CC::COND_A;
    break;
  }

  Cond[1].setImm(CC);
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

static bool AcceptsAdditionalEqualityCheck(DCPU16CC::CondCodes simpleCC,
                                           DCPU16CC::CondCodes *complexCC) {
  *complexCC = simpleCC;
  switch (simpleCC) {
  default: llvm_unreachable("Invalid comparison code!");
  case DCPU16CC::COND_GE:
  case DCPU16CC::COND_LE:
  case DCPU16CC::COND_AE:
  case DCPU16CC::COND_UE:
    llvm_unreachable("Not a simple CC, already contains an equality!");
  case DCPU16CC::COND_B:
  case DCPU16CC::COND_C:
  case DCPU16CC::COND_E:
  case DCPU16CC::COND_NE:
    return false;
  case DCPU16CC::COND_G:
    *complexCC = DCPU16CC::COND_GE;
    return true;
  case DCPU16CC::COND_A:
    *complexCC = DCPU16CC::COND_AE;
    return true;
  case DCPU16CC::COND_L:
    *complexCC = DCPU16CC::COND_LE;
    return true;
  case DCPU16CC::COND_U:
    *complexCC = DCPU16CC::COND_UE;
    return true;
  }
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
    assert(isBR_CC(I->getOpcode()) && "Invalid conditional branch");
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
      Cond.push_back(MachineOperand::CreateImm(I->getOpcode()));
      Cond.push_back(MachineOperand::CreateImm(BranchCode));
      Cond.push_back(LHS);
      Cond.push_back(RHS);
      continue;
    }

    assert(Cond.size() == 4);
    assert(TBB);

    // Is it a complex CC?
    DCPU16CC::CondCodes complexCC;
    if ((BranchCode == DCPU16CC::COND_E)
        && AcceptsAdditionalEqualityCheck((DCPU16CC::CondCodes) Cond[1].getImm(), &complexCC)
        && (TBB == I->getOperand(3).getMBB())
        // This should actually check for equality but that's just too much code...
        && (((Cond[2].getType() == LHS.getType()) && (Cond[3].getType() == RHS.getType()))
          || ((Cond[2].getType() == RHS.getType()) && (Cond[3].getType() == LHS.getType())))) {

      Cond[1] = MachineOperand::CreateImm(complexCC);
    }
  }

  return false;
}

static bool IsComplexCC(DCPU16CC::CondCodes cc,
                        DCPU16CC::CondCodes *simpleCC) {
  *simpleCC = cc;
  switch (cc) {
  default: llvm_unreachable("Invalid condition code!");
  case DCPU16CC::COND_B:
  case DCPU16CC::COND_C:
  case DCPU16CC::COND_E:
  case DCPU16CC::COND_NE:
  case DCPU16CC::COND_G:
  case DCPU16CC::COND_L:
  case DCPU16CC::COND_A:
  case DCPU16CC::COND_U:
    return false;
  case DCPU16CC::COND_GE:
    *simpleCC = DCPU16CC::COND_G;
    return true;
  case DCPU16CC::COND_LE:
    *simpleCC = DCPU16CC::COND_L;
    return true;
  case DCPU16CC::COND_AE:
    *simpleCC = DCPU16CC::COND_A;
    return true;
  case DCPU16CC::COND_UE:
    *simpleCC = DCPU16CC::COND_U;
    return true;
  }
}

unsigned
DCPU16InstrInfo::InsertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                              MachineBasicBlock *FBB,
                              const SmallVectorImpl<MachineOperand> &Cond,
                              DebugLoc DL) const {
  // Shouldn't be a fall through.
  assert(TBB && "InsertBranch must not be told to insert a fallthrough");
  assert((Cond.size() == 4 || Cond.size() == 0) &&
         "DCPU16 branch conditions have four components!");

  if (Cond.empty()) {
    // Unconditional branch?
    assert(!FBB && "Unconditional branch with multiple successors!");
    BuildMI(&MBB, DL, get(DCPU16::JMP)).addMBB(TBB);
    return 1;
  }

  // Conditional branch.
  unsigned Count = 0;
  unsigned Opcode = Cond[0].getImm();
  DCPU16CC::CondCodes CC = (DCPU16CC::CondCodes) Cond[1].getImm();
  MachineOperand LHS = Cond[2];
  MachineOperand RHS = Cond[3];

  // Is it a complex CC?
  DCPU16CC::CondCodes simpleCC;
  if (IsComplexCC(CC, &simpleCC)) {
    BuildMI(&MBB, DL, get(Opcode))
      .addImm(DCPU16CC::COND_E)
      .addOperand(LHS).addOperand(RHS)
      .addMBB(TBB);
    CC = simpleCC;
    ++Count;
  }
  BuildMI(&MBB, DL, get(Opcode))
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

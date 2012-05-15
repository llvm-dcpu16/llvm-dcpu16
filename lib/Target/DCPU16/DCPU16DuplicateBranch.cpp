//===-- DCPU16DuplicateBranch.cpp - DCPU16 Duplicate Branch Optimization --===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This pass optimizes "duplicate" branches. This can happen if we have a
// sequence as follows (pseudocode):
//
// if (a == b) {
//   goto branch1;
// } else if (a >= b) {
//   goto branch2;
// }
//
// Due to the slightly strange branches of the DCPU16, this will be assembled
// to:
//
// ; a == b
// IFE A, B
// SET PC, branch1
// ; a >= b
// IFE A, B
// SET PC, branch2
// IFG A, B
// SET PC, branch2
//
// As you can see, the second `IFE` is superfluous and can be deleted.
//
// CAUTION: Only run this pass just before machine code generation (or any
// other time when it is guaranteed that the relative position of basic blocks
// doesn't change anymore)!
//
//===----------------------------------------------------------------------===//

#include "DCPU16.h"
#include "DCPU16TargetMachine.h"
#include "llvm/CodeGen/MachineFunctionPass.h"

using namespace llvm;

namespace {
  class DCPU16DuplicateBranch : public MachineFunctionPass {

  public:
    static char ID;
    DCPU16DuplicateBranch() : MachineFunctionPass(ID) { }

    bool runOnMachineFunction(MachineFunction &MF);

    const char *getPassName() const {
      return "DCPU16 duplicate branch optimization";
    }
  };
}

char DCPU16DuplicateBranch::ID = 0; 

static bool isSameMachineOperand(MachineOperand &MO1, MachineOperand &MO2) {
  if (MO1.isImm()) {
    if (!MO2.isImm() || MO1.getImm() != MO2.getImm())
      return false;
  } else if (MO1.isReg()) {
    if (!MO2.isReg() || MO1.getReg() != MO2.getReg())
      return false;
  } else {
    assert(false && "Only registers and immediates supported");
  }
  return true;
}

static bool isSameBR_CC(MachineInstr *MI1, MachineInstr *MI2) {
  assert(isBR_CC(MI1->getOpcode()) && "not a BR_CC");
  assert(isBR_CC(MI2->getOpcode()) && "not a BR_CC");
  if (MI1->getOpcode() != MI2->getOpcode())
    // Different opcode (and as a result different LHS/RHS)
    return false;
  if (MI1->getOperand(0).getImm() != MI2->getOperand(0).getImm())
    // Different comparison/branch code
    return false;
  MachineOperand &LHS1 = MI1->getOperand(1);
  MachineOperand &RHS1 = MI1->getOperand(2);
  MachineOperand &LHS2 = MI2->getOperand(1);
  MachineOperand &RHS2 = MI2->getOperand(2);
  if (!isSameMachineOperand(LHS1, LHS2) || !isSameMachineOperand(RHS1, RHS2))
    return false;

  return true;
}

bool DCPU16DuplicateBranch::runOnMachineFunction(MachineFunction &MF) {
  bool Changed = false;
  // Kept when iterating over basic blocks. Should be ok, as long as this
  // pass is only used at the end (i.e. just before machine code generation).
  MachineInstr *prevBRCC = NULL;

  // Loop over all of the basic blocks.
  for (MachineFunction::iterator MBBb = MF.begin(), MBBe = MF.end();
       MBBb != MBBe; ++MBBb) {

    MachineBasicBlock* MBB = MBBb;

    // Traverse the basic block.
    for (MachineBasicBlock::iterator MII = MBB->begin(), MIIe = MBB->end();
         MII != MIIe; ++MII) {

      MachineInstr *MI = MII;

      if (isBR_CC(MI->getOpcode())) {
        if (prevBRCC != NULL
            && isSameBR_CC(prevBRCC, MI)) {

          MII->eraseFromParent();
          // Restart loop
          MII = MBB->begin();
          prevBRCC = NULL;

          Changed = true;
        } else {
          prevBRCC = MI;
        }
      } else {
        prevBRCC = NULL;
      }
    }
  }

  return Changed;
}

FunctionPass *llvm::createDCPU16DuplicateBranch() {
  return new DCPU16DuplicateBranch();
}

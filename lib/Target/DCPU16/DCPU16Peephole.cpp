//===-- DCPU16Peephole.cpp - DCPU16 Peephole Optimiztions ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// This peephole pass optimizes in the following cases.
// 1. Optimizes redundant sign extends for the following case
//    Transform the following pattern
//    %vreg170<def> = SXTW %vreg166
//    ...
//    %vreg176<def> = COPY %vreg170:subreg_loreg
//
//    Into
//    %vreg176<def> = COPY vreg166
//
//  2. Optimizes redundant negation of predicates.
//     %vreg15<def> = CMPGTrr %vreg6, %vreg2
//     ...
//     %vreg16<def> = NOT_p %vreg15<kill>
//     ...
//     JMP_c %vreg16<kill>, <BB#1>, %PC<imp-def,dead>
//
//     Into
//     %vreg15<def> = CMPGTrr %vreg6, %vreg2;
//     ...
//     JMP_cNot %vreg15<kill>, <BB#1>, %PC<imp-def,dead>;
//
// Note: The peephole pass makes the instrucstions like
// %vreg170<def> = SXTW %vreg166 or %vreg16<def> = NOT_p %vreg15<kill>
// redundant and relies on some form of dead removal instrucions, like
// DCE or DIE to actually eliminate them.


//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "DCPU16-peephole"
#include "DCPU16.h"
#include "DCPU16TargetMachine.h"
#include "DCPU16InstrInfo.h"
#include "llvm/Constants.h"
#include "llvm/PassSupport.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetRegisterInfo.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/MC/MCSymbol.h"
#include <algorithm>
#include <iostream>

using namespace llvm;

static cl::opt<bool> DisableDCPU16Peephole("disable-dcpu16-peephole",
    cl::Hidden, cl::ZeroOrMore, cl::init(false),
    cl::desc("Disable Peephole Optimization"));

static cl::opt<bool> DisableOptIFA("disable-dcpu16-ifa",
    cl::Hidden, cl::ZeroOrMore, cl::init(false),
    cl::desc("Disable IFA Optimization"));

namespace {
  struct DCPU16Peephole : public MachineFunctionPass {
    const DCPU16InstrInfo    *QII;
    const DCPU16RegisterInfo *QRI;
    const MachineRegisterInfo *MRI;

  public:
    static char ID;
    DCPU16Peephole() : MachineFunctionPass(ID) { }

    bool runOnMachineFunction(MachineFunction &MF);

    const char *getPassName() const {
      return "DCPU16 optimize redundant zero and size extends";
    }

    void getAnalysisUsage(AnalysisUsage &AU) const {
      MachineFunctionPass::getAnalysisUsage(AU);
    }
  };
}

char DCPU16Peephole::ID = 0;

bool DCPU16Peephole::runOnMachineFunction(MachineFunction &MF) {
  QII = static_cast<const DCPU16InstrInfo *>(MF.getTarget().
                                        getInstrInfo());
  QRI = static_cast<const DCPU16RegisterInfo *>(MF.getTarget().
                                       getRegisterInfo());
  MRI = &MF.getRegInfo();

  DenseMap<unsigned, unsigned> PeepholeMap;

  if (DisableDCPU16Peephole) return false;

  // Loop over all of the basic blocks.
  for (MachineFunction::iterator MBBb = MF.begin(), MBBe = MF.end();
       MBBb != MBBe; ++MBBb) {
    MachineBasicBlock* MBB = MBBb;
    PeepholeMap.clear();
    std::cout << std::endl;
    
    // Search for AND, IFE
    
    if (!DisableOptIFA) {
      
      // Traverse the basic block.
      for (MachineBasicBlock::iterator MII = MBB->begin(); MII != MBB->end();
                                       ++MII) {
        MachineInstr *MI = MII;
        
        if(!DisableOptIFA && (
           MI->getOpcode() == DCPU16::AND16rm ||
           MI->getOpcode() == DCPU16::AND16ri ||
           MI->getOpcode() == DCPU16::AND16mr ||
           MI->getOpcode() == DCPU16::AND16mi ||
           MI->getOpcode() == DCPU16::AND16mm ||
           MI->getOpcode() == DCPU16::AND16rr
        )) {
          switch(MI->getOpcode()) {
            case DCPU16::AND16ri: {
              assert (MI->getNumOperands() == 4);
              
              MachineOperand &Dst = MI->getOperand(0);
              MachineOperand &Src  = MI->getOperand(1);
              unsigned DstReg = Dst.getReg();
              unsigned SrcReg = Src.getReg();
              
              MI->dump();
              
              if (TargetRegisterInfo::isVirtualRegister(DstReg) &&
                TargetRegisterInfo::isVirtualRegister(SrcReg)) {
                PeepholeMap[DstReg] = SrcReg;
              }
            }
          }
        }

        MI->dump();
        
        if(!DisableOptIFA && (
           MI->getOpcode() == DCPU16CC::COND_NE
        )) {
          switch(MI->getOpcode()) {
            case DCPU16CC::COND_NE: {
              /*assert (MI->getNumOperands() == 4);
              
              MachineOperand &Dst = MI->getOperand(0);
              MachineOperand &Src  = MI->getOperand(1);
              unsigned DstReg = Dst.getReg();
              unsigned SrcReg = Src.getReg();
              
              
              
              if (TargetRegisterInfo::isVirtualRegister(DstReg) &&
                TargetRegisterInfo::isVirtualRegister(SrcReg)) {
                PeepholeMap[DstReg] = SrcReg;
              }*/
            }
          }
        }
      } // Instruction
    }
  } // Basic Block
  return true;
}

FunctionPass *llvm::createDCPU16Peephole() {
  return new DCPU16Peephole();
}


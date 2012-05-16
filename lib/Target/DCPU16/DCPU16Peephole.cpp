//===-- DCPU16Peephole.cpp - DCPU16 Peephole Optimiztions ---------------===//
//
//										 The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// This peephole pass optimizes in the following cases.
// 1. Optimizes redundant sign extends for the following case
//		Transform the following pattern
//		%vreg170<def> = SXTW %vreg166
//		...
//		%vreg176<def> = COPY %vreg170:subreg_loreg
//
//		Into
//		%vreg176<def> = COPY vreg166
//
//	2. Optimizes redundant negation of predicates.
//		 %vreg15<def> = CMPGTrr %vreg6, %vreg2
//		 ...
//		 %vreg16<def> = NOT_p %vreg15<kill>
//		 ...
//		 JMP_c %vreg16<kill>, <BB#1>, %PC<imp-def,dead>
//
//		 Into
//		 %vreg15<def> = CMPGTrr %vreg6, %vreg2;
//		 ...
//		 JMP_cNot %vreg15<kill>, <BB#1>, %PC<imp-def,dead>;
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

static cl::opt<bool> DisableDCPU16Peephole(
	"disable-dcpu16-peephole",
	cl::Hidden,
	cl::ZeroOrMore,
	cl::init(false),
	cl::desc("Disable Peephole Optimisations")
);

static cl::opt<bool> DisableOptBrcc(
	"disable-dcpu16-brcc",
	cl::Hidden, cl::ZeroOrMore, cl::init(false),
	cl::desc("Disable Conditional Branch Optimization")
);

namespace {
	struct DCPU16Peephole : public MachineFunctionPass {
		const DCPU16InstrInfo		*QII;
		const DCPU16RegisterInfo	*QRI;
		const MachineRegisterInfo	*MRI;

	public:
		static char ID;
		DCPU16Peephole() : MachineFunctionPass(ID) { }

		bool runOnMachineFunction(MachineFunction &MF);
		void runOptBrcc(MachineBasicBlock *mbb);

		const char *getPassName() const {
			return "DCPU16 optimize conditional branches";
		}

		void getAnalysisUsage(AnalysisUsage &AU) const {
			MachineFunctionPass::getAnalysisUsage(AU);
		}
	};
}

char DCPU16Peephole::ID = 0;

void DCPU16Peephole::runOptBrcc(MachineBasicBlock *mbb) {
	// Dump the block (remove when done)
	mbb->dump();
	std::cout << std::endl;
	
	DenseMap<unsigned, MachineInstr *> peepholeMap;
	
	for(MachineBasicBlock::iterator miiIter = mbb->begin(); miiIter != mbb->end(); ++miiIter) {
		MachineInstr *instruction = miiIter;	
		
		switch(instruction->getOpcode()) {
			// And instructions
			// AND register, immediate
			case DCPU16::AND16ri: {
				assert(instruction->getNumOperands() == 4);
				
				// %vreg1<def> = AND16ri %vreg0, [immediate], %EX<imp-def,dead>; GR16:%vreg1,%vreg0
				MachineOperand &result = instruction->getOperand(0);
				unsigned resultReg = result.getReg();
				
				if(TargetRegisterInfo::isVirtualRegister(resultReg))
					peepholeMap[resultReg] = instruction;
				
				break;
			}
			
			// Branch instructions
			case DCPU16::BR_CCri: {
				switch(instruction->getOperand(0).getImm()) {
					case DCPU16CC::COND_NE: {
						assert(instruction->getNumOperands() == 4);
						
						// BR_CCri 3, %vreg1, 0, <BB#2>; GR16:%vreg1
						MachineOperand &brImm = instruction->getOperand(0);
						MachineOperand &oldA = instruction->getOperand(1);
						MachineOperand &oldB = instruction->getOperand(2);
						if(oldB.getImm() != 0) break; // lhs == 0
						
						MachineOperand &regOperand = instruction->getOperand(1);
						unsigned vReg = regOperand.getReg();
						
						if(TargetRegisterInfo::isVirtualRegister(vReg)) {
							if(MachineInstr *peepholeSource = peepholeMap.lookup(vReg)) {
								MachineOperand &newA = peepholeSource->getOperand(1);
								MachineOperand &newB = peepholeSource->getOperand(2);
								assert(newA.isReg() && newB.isImm() && "Encountered wrong operands in DCPU-16 BR_CCri peephole opt");
								
								unsigned vReg = regOperand.getReg();
								
								// Change the IFN to IFB and swap the operands
								brImm.setImm(DCPU16CC::COND_B);
								oldA.setReg(newA.getReg());
								oldB.setImm(newB.getImm());
								
								// Remove the AND
								peepholeSource->eraseFromParent();
								
								std::cout << "Changed to:" << std::endl;
								instruction->dump();
								std::cout << std::endl;
							}
						}
						
						break;
					}
				}
			}
		}
	}
}

bool DCPU16Peephole::runOnMachineFunction(MachineFunction &MF) {
	QII = static_cast<const DCPU16InstrInfo *>(MF.getTarget().getInstrInfo());
	QRI = static_cast<const DCPU16RegisterInfo *>(MF.getTarget().getRegisterInfo());
	MRI = &MF.getRegInfo();
	
	// Disable all peephole optimisations
	if(DisableDCPU16Peephole) return false;

	// Loop over all of the basic blocks.
	for(MachineFunction::iterator mbbIter = MF.begin(); mbbIter != MF.end(); ++mbbIter) {
		MachineBasicBlock *mbb = mbbIter;
		
		if(!DisableOptBrcc) runOptBrcc(mbb);
		
		/*// Search for AND, IFE
		if (!DisableOptIFA) {
			
			// Traverse the basic block.
			for (MachineBasicBlock::iterator MII = MBB->begin(); MII != MBB->end();
																			 ++MII) {
				MachineInstr *MI = MII;
				
				if (!DisableOptIFA && (
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
							MachineOperand &Src	= MI->getOperand(1);
							unsigned DstReg = Dst.getReg();
							unsigned SrcReg = Src.getReg();
							
							if (TargetRegisterInfo::isVirtualRegister(DstReg) &&
								TargetRegisterInfo::isVirtualRegister(SrcReg)) {
								PeepholeMap[DstReg] = SrcReg;
							}
						}
					}
				}
				
				if (!DisableOptIFA && (
					 MI->getOpcode() == DCPU16::BR_CCri
				)) {
					switch (MI->getOperand(0).getImm()) {
						case DCPU16CC::COND_NE: {
							assert (MI->getNumOperands() == 4);
							
							if (MI->getOperand(2).getImm() != 0) break;
							
							MachineOperand &Src = MI->getOperand(1);
							unsigned SrcReg = Src.getReg();
							
							if (TargetRegisterInfo::isVirtualRegister(SrcReg)) {
								// Try to find in the map.
								if (unsigned PeepholeSrc = PeepholeMap.lookup(SrcReg)) {
									// Change the 1st operand.
									MI->RemoveOperand(3);
									MI->addOperand(MachineOperand::CreateImm(53264));
									
									std::cout << std::endl;
									std::cout << "Optimise here plz" << std::endl;
									MI->dump();
									std::cout << std::endl;
								}
							}
							
							if (TargetRegisterInfo::isVirtualRegister(DstReg) &&
								TargetRegisterInfo::isVirtualRegister(SrcReg)) {
								PeepholeMap[DstReg] = SrcReg;
							}
						}
					}
				}
			} // Instruction
		}*/
	} // Basic Block
	return true;
}

FunctionPass *llvm::createDCPU16Peephole() {
	return new DCPU16Peephole();
}


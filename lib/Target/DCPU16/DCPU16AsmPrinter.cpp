//===-- DCPU16AsmPrinter.cpp - DCPU16 LLVM assembly writer ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to the DCPU16 assembly language.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"
#include "DCPU16.h"
#include "DCPU16InstrInfo.h"
#include "DCPU16MCInstLower.h"
#include "DCPU16TargetMachine.h"
#include "InstPrinter/DCPU16InstPrinter.h"
#include "llvm/Constants.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Module.h"
#include "llvm/Assembly/Writer.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Target/Mangler.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

namespace {
  class DCPU16AsmPrinter : public AsmPrinter {
  public:
    DCPU16AsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
      : AsmPrinter(TM, Streamer) {}

    virtual const char *getPassName() const {
      return "DCPU16 Assembly Printer";
    }

    void printOperand(const MachineInstr *MI, int OpNum,
                      raw_ostream &O, const char* Modifier = 0);
    void printSrcMemOperand(const MachineInstr *MI, int OpNum,
                            raw_ostream &O);
    bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                         unsigned AsmVariant, const char *ExtraCode,
                         raw_ostream &O);
    bool PrintAsmMemoryOperand(const MachineInstr *MI,
                               unsigned OpNo, unsigned AsmVariant,
                               const char *ExtraCode, raw_ostream &O);
    void EmitInstruction(const MachineInstr *MI);
  };
} // end of anonymous namespace


void DCPU16AsmPrinter::printOperand(const MachineInstr *MI, int OpNum,
                                    raw_ostream &O, const char *Modifier) {
  const MachineOperand &MO = MI->getOperand(OpNum);
  switch (MO.getType()) {
  default: llvm_unreachable("Not implemented yet!");
  case MachineOperand::MO_Register:
    O << DCPU16InstPrinter::getRegisterName(MO.getReg());
    return;
  case MachineOperand::MO_Immediate:
    O << MO.getImm();
    return;
  case MachineOperand::MO_MachineBasicBlock:
    O << *MO.getMBB()->getSymbol();
    return;
  case MachineOperand::MO_GlobalAddress: {
    bool isMemOp  = Modifier && !strcmp(Modifier, "mem");
    uint64_t Offset = MO.getOffset();

    if (isMemOp) O << '[';
    O << *Mang->getSymbol(MO.getGlobal());
    if (Offset)
      O << '+' << Offset;
    if (isMemOp) O << ']';

    return;
  }
  case MachineOperand::MO_ExternalSymbol: {
    bool isMemOp  = Modifier && !strcmp(Modifier, "mem");
    if (isMemOp) O << '[';
    O << MAI->getGlobalPrefix() << MO.getSymbolName();
    if (isMemOp) O << ']';
    return;
  }
  }
}

void DCPU16AsmPrinter::printSrcMemOperand(const MachineInstr *MI, int OpNum,
                                          raw_ostream &O) {
  const MachineOperand &Base = MI->getOperand(OpNum);
  const MachineOperand &Disp = MI->getOperand(OpNum+1);

  // Special case for PICK n syntax
  if (Base.getReg() == DCPU16::SP) {
    if (Disp.isImm()) {
      if (Disp.getImm() == 0) {
        O << "PEEK";  // equiv. to [SP]
      } else {
        O << "PICK 0x"; // equiv. to [SP+x]
        O.write_hex(Disp.getImm() & 0xFFFF);
      }
    } else {
      llvm_unreachable("Unsupported src mem expression in inline asm");
    }
    return;
  }

  O << '[';

  if (Base.getReg()) {
    O << DCPU16InstPrinter::getRegisterName(Base.getReg());
  }

  if (Base.getReg()) {
    // Only print the immediate if it isn't 0, easier to read and
    // generates more efficient code on bad assemblers
    if (Disp.getImm() != 0) {
      O << "+";
      O << "0x";
      O.write_hex(Disp.getImm() & 0xFFFF);
    }
  } else {
    O << "0x";
    O.write_hex(Disp.getImm() & 0xFFFF);
  }

  O << ']';
}

/// PrintAsmOperand - Print out an operand for an inline asm expression.
///
bool DCPU16AsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                       unsigned AsmVariant,
                                       const char *ExtraCode, raw_ostream &O) {
  // Does this asm operand have a single letter operand modifier?
  if (ExtraCode && ExtraCode[0])
    return true; // Unknown modifier.

  printOperand(MI, OpNo, O);
  return false;
}

bool DCPU16AsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                             unsigned OpNo, unsigned AsmVariant,
                                             const char *ExtraCode,
                                             raw_ostream &O) {
  if (ExtraCode && ExtraCode[0]) {
    return true; // Unknown modifier.
  }
  printSrcMemOperand(MI, OpNo, O);
  return false;
}

//===----------------------------------------------------------------------===//
void DCPU16AsmPrinter::EmitInstruction(const MachineInstr *MI) {
  DCPU16MCInstLower MCInstLowering(OutContext, *Mang, *this);

  MCInst TmpInst;
  MCInstLowering.Lower(MI, TmpInst);
  OutStreamer.EmitInstruction(TmpInst);
}

// Force static initialization.
extern "C" void LLVMInitializeDCPU16AsmPrinter() {
  RegisterAsmPrinter<DCPU16AsmPrinter> X(TheDCPU16Target);
}

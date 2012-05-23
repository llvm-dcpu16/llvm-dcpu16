//===-- DCPU16InstPrinter.cpp - Convert DCPU16 MCInst to assembly syntax --===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an DCPU16 MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"

#include "DCPU16.h"
#include "DCPU16InstPrinter.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"
using namespace llvm;

// Include the auto-generated portion of the assembly writer.
#include "DCPU16GenAsmWriter.inc"

void DCPU16InstPrinter::printInst(const MCInst *MI, raw_ostream &O,
                                  StringRef Annot) {
  printInstruction(MI, O);
  printAnnotation(O, Annot);
}

void DCPU16InstPrinter::printPCRelImmOperand(const MCInst *MI, unsigned OpNo,
                                             raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm())  {
	  O << "0x";
	  O.write_hex((Op.getImm()) & 0xFFFF);
  } else {
    assert(Op.isExpr() && "unknown pcrel immediate operand");
    O << *Op.getExpr();
  }
}

void DCPU16InstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                     raw_ostream &O, const char *Modifier) {
  assert((Modifier == 0 || Modifier[0] == 0) && "No modifiers supported");
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    O << getRegisterName(Op.getReg());
  } else if (Op.isImm()) {
	  O << "0x";
	  O.write_hex(Op.getImm() & 0xFFFF);
  } else {
    assert(Op.isExpr() && "unknown operand kind in printOperand");
    O << *Op.getExpr();
  }
}

void DCPU16InstPrinter::printSrcMemOperand(const MCInst *MI, unsigned OpNo,
                                           raw_ostream &O,
                                           const char *Modifier) {
  const MCOperand &Base = MI->getOperand(OpNo);
  const MCOperand &Disp = MI->getOperand(OpNo+1);

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
      assert(Disp.isExpr() &&
             "Expected immediate or expression in displacement field");
      O << "PICK ";
      O << *Disp.getExpr();
    }
    return;
  }

  O << '[';

  if (Base.getReg()) {
    O << getRegisterName(Base.getReg());
  }

  if (Disp.isExpr()) {
    if (Base.getReg())
      O << "+";
    O << *Disp.getExpr();
  } else {
    assert(Disp.isImm() &&
        "Expected immediate or expression in displacement field");
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
  }

  O << ']';
}

void DCPU16InstPrinter::printCCOperand(const MCInst *MI, unsigned OpNo,
                                       raw_ostream &O) {
  unsigned CC = MI->getOperand(OpNo).getImm();

  switch (CC) {
  default:
    llvm_unreachable("Unsupported CC code");
  case DCPU16CC::COND_B:
    O << "IFB";
    break;
  case DCPU16CC::COND_C:
    O << "IFC";
    break;
  case DCPU16CC::COND_E:
    O << "IFE";
    break;
  case DCPU16CC::COND_NE:
    O << "IFN";
    break;
  case DCPU16CC::COND_G:
    O << "IFG";
    break;
  case DCPU16CC::COND_A:
    O << "IFA";
    break;
  case DCPU16CC::COND_L:
    O << "IFL";
    break;
  case DCPU16CC::COND_U:
    O << "IFU";
    break;
  }
}

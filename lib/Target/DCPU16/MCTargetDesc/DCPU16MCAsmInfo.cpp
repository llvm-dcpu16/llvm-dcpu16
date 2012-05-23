//===-- DCPU16MCAsmInfo.cpp - DCPU16 asm properties -----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the DCPU16MCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "DCPU16MCAsmInfo.h"
#include "llvm/ADT/StringRef.h"
using namespace llvm;

void DCPU16MCAsmInfo::anchor() { }

DCPU16MCAsmInfo::DCPU16MCAsmInfo(const Target &T, StringRef TT) {
  LabelPrefix = ":";
  LabelSuffix = "";
  PointerSize = 2;

  PrivateGlobalPrefix = ".L";
  WeakRefDirective ="\t.weak\t";
  PCSymbol=".";
  CommentString = ";";

  AlignmentIsInBytes = false;
  // TODO(krasin): support .align
  // https://github.com/krasin/llvm-dcpu16/issues/52
  AlignDirective = "\t; .align\t";
  AllowNameToStartWithDigit = true;
  UsesELFSectionDirectiveForBSS = false;
  HasDotTypeDotSizeDirective = false;

  // Use .lcomm instead of .local .comm (required for binutils support)
  LCOMMDirectiveType = LCOMM::NoAlignment;
}

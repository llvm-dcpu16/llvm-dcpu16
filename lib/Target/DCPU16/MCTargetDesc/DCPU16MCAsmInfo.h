//===-- DCPU16MCAsmInfo.h - DCPU16 asm properties --------------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the DCPU16MCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef DCPU16TARGETASMINFO_H
#define DCPU16TARGETASMINFO_H

#include "llvm/MC/MCAsmInfo.h"

namespace llvm {
  class StringRef;
  class Target;

  class DCPU16MCAsmInfo : public MCAsmInfo {
    virtual void anchor();
  public:
    explicit DCPU16MCAsmInfo(const Target &T, StringRef TT);
  };

} // namespace llvm

#endif

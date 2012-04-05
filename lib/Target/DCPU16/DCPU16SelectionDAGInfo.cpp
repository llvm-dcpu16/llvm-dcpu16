//===-- DCPU16SelectionDAGInfo.cpp - DCPU16 SelectionDAG Info -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the DCPU16SelectionDAGInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "dcpu16-selectiondag-info"
#include "DCPU16TargetMachine.h"
using namespace llvm;

DCPU16SelectionDAGInfo::DCPU16SelectionDAGInfo(const DCPU16TargetMachine &TM)
  : TargetSelectionDAGInfo(TM) {
}

DCPU16SelectionDAGInfo::~DCPU16SelectionDAGInfo() {
}

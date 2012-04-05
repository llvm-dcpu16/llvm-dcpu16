##===- lib/Target/DCPU16/Makefile --------------------------*- Makefile -*-===##
# 
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source 
# License. See LICENSE.TXT for details.
# 
##===----------------------------------------------------------------------===##

LEVEL = ../../..
LIBRARYNAME = LLVMDCPU16CodeGen
TARGET = DCPU16

# Make sure that tblgen is run, first thing.
BUILT_SOURCES = DCPU16GenRegisterInfo.inc DCPU16GenInstrInfo.inc \
		DCPU16GenAsmWriter.inc \
		DCPU16GenDAGISel.inc DCPU16GenCallingConv.inc \
		DCPU16GenSubtargetInfo.inc

DIRS = InstPrinter TargetInfo MCTargetDesc

include $(LEVEL)/Makefile.common


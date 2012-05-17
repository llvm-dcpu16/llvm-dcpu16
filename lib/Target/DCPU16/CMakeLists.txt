set(LLVM_TARGET_DEFINITIONS DCPU16.td)

tablegen(LLVM DCPU16GenRegisterInfo.inc -gen-register-info)
tablegen(LLVM DCPU16GenInstrInfo.inc -gen-instr-info)
tablegen(LLVM DCPU16GenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM DCPU16GenDAGISel.inc -gen-dag-isel)
tablegen(LLVM DCPU16GenCallingConv.inc -gen-callingconv)
tablegen(LLVM DCPU16GenSubtargetInfo.inc -gen-subtarget)
add_public_tablegen_target(DCPU16CommonTableGen)

add_llvm_target(DCPU16CodeGen
  DCPU16ISelDAGToDAG.cpp
  DCPU16ISelLowering.cpp
  DCPU16InstrInfo.cpp
  DCPU16FrameLowering.cpp
  DCPU16MachineFunctionInfo.cpp
  DCPU16RegisterInfo.cpp
  DCPU16Subtarget.cpp
  DCPU16TargetMachine.cpp
  DCPU16SelectionDAGInfo.cpp
  DCPU16AsmPrinter.cpp
  DCPU16MCInstLower.cpp
  DCPU16Peephole.cpp
  )

add_subdirectory(InstPrinter)
add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)

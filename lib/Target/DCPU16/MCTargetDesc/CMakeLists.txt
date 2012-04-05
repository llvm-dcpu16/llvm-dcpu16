add_llvm_library(LLVMDCPU16Desc
  DCPU16MCTargetDesc.cpp
  DCPU16MCAsmInfo.cpp
  )

add_dependencies(LLVMDCPU16Desc DCPU16CommonTableGen)

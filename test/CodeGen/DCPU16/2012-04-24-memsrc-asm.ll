; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @func() nounwind {
entry:
  %x = alloca i16, align 1
  call void asm sideeffect "SET $0, SP", "=*m"(i16* %x) nounwind, !srcloc !0
  %0 = load i16* %x, align 1
  ret i16 %0
}

!0 = metadata !{i32 58}

; CHECK: :func
; CHECK: SET PEEK, SP

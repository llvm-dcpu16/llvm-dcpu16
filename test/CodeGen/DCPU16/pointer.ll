; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8-s0:8:8-n16"
target triple = "dcpu16"

define void @simpleInc() nounwind {
entry:
  %ptr = alloca i16*, align 1
  store i16* inttoptr (i16 -32768 to i16*), i16** %ptr, align 1
  %0 = load i16** %ptr, align 1
  %add.ptr = getelementptr inbounds i16* %0, i16 1
  store i16* %add.ptr, i16** %ptr, align 1
  ret void
}

; CHECK: :simpleInc
; CHECK: SET [I], 0x8000
; CHECK: SET [I], 0x8001
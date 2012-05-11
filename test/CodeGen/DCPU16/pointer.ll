; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
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
; CHECK: SET PEEK, 0x8000
; CHECK: SET PEEK, 0x8001

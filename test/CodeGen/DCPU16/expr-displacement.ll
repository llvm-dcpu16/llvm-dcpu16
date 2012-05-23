; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

@lookup_list = global [6 x i16] [i16 97, i16 98, i16 99, i16 100, i16 101, i16 0], align 1

define void @lookup(i16* nocapture %ptr, i16 %index) nounwind {
entry:
  %arrayidx = getelementptr inbounds [6 x i16]* @lookup_list, i16 0, i16 %index
  %0 = load i16* %arrayidx, align 1
  store i16 %0, i16* %ptr, align 1
  ret void
}
; CHECK: :lookup
; CHECK: SET [A], [B+lookup_list]

; CHECK: :lookup_list

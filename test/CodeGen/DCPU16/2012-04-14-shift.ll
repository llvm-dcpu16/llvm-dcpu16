; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8-s0:8:8-n16"
target triple = "dcpu16"

define i16 @shift_ri(i16 %a) nounwind readnone {
entry:
  %shr = ashr i16 %a, 8
  ret i16 %shr
}
; CHECK: :shift_ri
; CHECK: SHR A, 0x8

define i16 @shift_li(i16 %a) nounwind readnone {
entry:
  %shl = shl i16 %a, 8
  ret i16 %shl
}
; CHECK: :shift_li
; CHECK: SHL A, 0x8

define i16 @shift_rr(i16 %a, i16 %b) nounwind readnone {
entry:
  %shr = ashr i16 %a, %b
  ret i16 %shr
}
; CHECK: :shift_rr
; CHECK: SHR A, B

define i16 @shift_lr(i16 %a, i16 %b) nounwind readnone {
entry:
  %shl = shl i16 %a, %b
  ret i16 %shl
}
; CHECK: :shift_lr
; CHECK: SHL A, B

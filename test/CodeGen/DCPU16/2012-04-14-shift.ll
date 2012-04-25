; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @shift_ri(i16 %a) nounwind readnone {
entry:
  %shr = ashr i16 %a, 8
  ret i16 %shr
}
; CHECK: :shift_ri
; CHECK: ASR A, 0x8

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
; CHECK: ASR A, B

define i16 @shift_lr(i16 %a, i16 %b) nounwind readnone {
entry:
  %shl = shl i16 %a, %b
  ret i16 %shl
}
; CHECK: :shift_lr
; CHECK: SHL A, B

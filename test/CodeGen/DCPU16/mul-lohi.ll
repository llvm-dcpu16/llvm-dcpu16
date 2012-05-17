; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i32 @smul_lohi(i16 %a, i16 %b) nounwind readnone {
entry:
  %conv = sext i16 %a to i32
  %conv1 = sext i16 %b to i32
  %mul = mul nsw i32 %conv1, %conv
  ret i32 %mul
}
; CHECK: smul_lohi
; CHECK: MLI A, B
; CHECK: SET B, EX

define i32 @umul_lohi(i16 %a, i16 %b) nounwind readnone {
entry:
  %conv = zext i16 %a to i32
  %conv1 = zext i16 %b to i32
  %mul = mul i32 %conv1, %conv
  ret i32 %mul
}
; CHECK: :umul_lohi
; CHECK: MUL A, B
; CHECK: SET B, EX

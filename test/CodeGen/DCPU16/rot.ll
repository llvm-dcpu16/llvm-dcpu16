; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @rotl(i16 %a, i16 %b) nounwind readnone {
entry:
  %shl = shl i16 %a, %b
  %sub = sub i16 16, %b
  %shr = lshr i16 %a, %sub
  %or = or i16 %shr, %shl
  ret i16 %or
}
; CHECK: :rotl
; CHECK: SHL A, B
; CHECK: BOR A, EX

define i16 @rotr(i16 %a, i16 %b) nounwind readnone {
entry:
  %sub = sub i16 16, %b
  %shl = shl i16 %a, %sub
  %shr = lshr i16 %a, %b
  %or = or i16 %shl, %shr
  ret i16 %or
}
; CHECK: :rotr
; CHECK: SHR A, B
; CHECK: BOR A, EX

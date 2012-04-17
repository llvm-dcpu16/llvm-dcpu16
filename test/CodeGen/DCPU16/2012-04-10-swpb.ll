; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8-s0:8:8-n16"
target triple = "dcpu16"

define i16 @swpb(i16 %x) nounwind readnone {
entry:
  %shl = shl i16 %x, 8
  %shr = ashr i16 %x, 8
  %or = or i16 %shl, %shr
  ret i16 %or
}
; CHECK: :swpb
; CHECK: SET B, A
; CHECK: SHR B, 0x8
; CHECK: SHL A, 0x8
; CHECK: BOR A, B

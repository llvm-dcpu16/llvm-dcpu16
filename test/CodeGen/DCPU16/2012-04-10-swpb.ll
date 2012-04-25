; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
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
; CHECK: ASR B, 0x8
; CHECK: SHL A, 0x8
; CHECK: BOR A, B

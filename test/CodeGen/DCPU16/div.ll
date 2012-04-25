; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @udiv(i16 %a, i16 %b, i16* nocapture %c) nounwind readonly {
entry:
  %div = udiv i16 %a, %b
  %0 = load i16* %c, align 2
  %div1 = udiv i16 %a, %0
  %div2 = udiv i16 %a, 17
  %add = add i16 %div1, %div
  %add3 = add i16 %add, %div2
  ret i16 %add3
}
; CHECK: :udiv
; CHECK: DIV X, B
; CHECK: DIV B, [C]
; CHECK: DIV A, 0x11


define i16 @sdiv(i16 %a, i16 %b, i16* nocapture %c) nounwind readonly {
entry:
  %div = sdiv i16 %a, %b
  %0 = load i16* %c, align 2
  %div1 = sdiv i16 %a, %0
  %div2 = sdiv i16 %a, 17
  %add = add i16 %div1, %div
  %add3 = add i16 %add, %div2
  ret i16 %add3
}
; CHECK: :sdiv
; CHECK: DVI X, B
; CHECK: DVI B, [C]
; CHECK: DVI A, 0x11

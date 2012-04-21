; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @mod(i16 %a, i16 %b, i16* nocapture %c) nounwind readonly {
entry:
  %mod = urem i16 %a, %b
  %0 = load i16* %c, align 2
  %mod1 = urem i16 %a, %0
  %mod2 = urem i16 %a, 17
  %add = add i16 %mod1, %mod
  %add3 = add i16 %add, %mod2
  ret i16 %add3
}
; CHECK: :mod
; CHECK: MOD X, B
; CHECK: MOD B, [C]
; CHECK: MOD A, 0x11

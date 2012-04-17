; RUN: llc < %s -march=dcpu16 | FileCheck %s
; RUN: llc < %s -O0 -march=dcpu16 | FileCheck %s -check-prefix=CHECK-O0
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8-s0:8:8-n16"
target triple = "dcpu16"

define i16 @bic(i16 %a, i16 %b) nounwind readnone {
entry:
  %neg = xor i16 %b, -1
  %and = and i16 %neg, %a
  ret i16 %and
}
; CHECK: :bic
; CHECK: XOR B, 0xffff
; CHECK: AND A, B

; CHECK-O0: :bic
; CHECK-O0: XOR C, 0xffff
; CHECK-O0: AND C, A
; CHECK-O0: SET A, C

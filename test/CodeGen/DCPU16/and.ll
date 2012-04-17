; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8-s0:8:8-n16"
target triple = "dcpu16"

define i16 @f1(i16 %x, i16 %y) nounwind {
entry:
  %x.addr = alloca i16, align 1
  %y.addr = alloca i16, align 1
  store i16 %x, i16* %x.addr, align 1
  store i16 %y, i16* %y.addr, align 1
  %0 = load i16* %x.addr, align 1
  %1 = load i16* %y.addr, align 1
  %and = and i16 %0, %1
  ret i16 %and
}
; CHECK: :f1
; CHECK: SET [0x1+I], A
; CHECK: SET [I], B
; CHECK: AND B, [0x1+I]
; CHECK: SET A, B
; CHECK: ADD I, 0x2


define i16 @f2(i16 %x) nounwind {
entry:
  %x.addr = alloca i16, align 1
  store i16 %x, i16* %x.addr, align 1
  %0 = load i16* %x.addr, align 1
  %and = and i16 %0, 16
  ret i16 %and
}
; CHECK: :f2
; CHECK: AND A, 0x10

; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:8:8-i16:16:16-i32:16:32-i64:64:64-n8:16"
target triple = "dcpu16"

define i16 @f1(i16 %x, i16 %y) nounwind {
entry:
  %x.addr = alloca i16, align 2
  %y.addr = alloca i16, align 2
  store i16 %x, i16* %x.addr, align 2
  store i16 %y, i16* %y.addr, align 2
  %0 = load i16* %x.addr, align 2
  %1 = load i16* %y.addr, align 2
  %and = and i16 %0, %1
  ret i16 %and
}
; CHECK: :f1
; CHECK: SET [2+I], A
; CHECK: SET [I], B
; CHECK: AND B, [2+I]
; CHECK: SET A, B
; CHECK: ADD I, 4


define i16 @f2(i16 %x) nounwind {
entry:
  %x.addr = alloca i16, align 2
  store i16 %x, i16* %x.addr, align 2
  %0 = load i16* %x.addr, align 2
  %and = and i16 %0, 16
  ret i16 %and
}
; CHECK: :f2
; CHECK: AND A, 16

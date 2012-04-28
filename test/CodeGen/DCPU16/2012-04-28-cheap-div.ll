; RUN: llc < %s -march=dcpu16 | FileCheck %s
; ModuleID = 'test.c'
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @div2(i16 %a) nounwind {
entry:
  %a.addr = alloca i16, align 1
  store i16 %a, i16* %a.addr, align 1
  %0 = load i16* %a.addr, align 1
  %div = sdiv i16 %0, 2
  ret i16 %div
}
; CHECK: :div2
;CHECK:        DVI     A, 0x2


define i16 @div3(i16 %a) nounwind {
entry:
  %a.addr = alloca i16, align 1
  store i16 %a, i16* %a.addr, align 1
  %0 = load i16* %a.addr, align 1
  %div = sdiv i16 %0, 3
  ret i16 %div
}
; CHECK: :div3
;CHECK:        DVI     A, 0x3
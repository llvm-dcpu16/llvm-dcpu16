; RUN: llc < %s -march=dcpu16 | FileCheck %s
; ModuleID = 'test.c'
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @urem(i16 %i) nounwind {
entry:
  %i.addr = alloca i16, align 1
  store i16 %i, i16* %i.addr, align 1
  %0 = load i16* %i.addr, align 1
  %rem = urem i16 %0, 3
  ret i16 %rem
}

; CHECK: :urem
; CHECK: MOD A, 0x3

define i16 @srem(i16 %i) nounwind {
entry:
  %i.addr = alloca i16, align 1
  store i16 %i, i16* %i.addr, align 1
  %0 = load i16* %i.addr, align 1
  %rem = srem i16 %0, 3
  ret i16 %rem
}

; CHECK: :srem
; CHECK: MDI A, 0x3
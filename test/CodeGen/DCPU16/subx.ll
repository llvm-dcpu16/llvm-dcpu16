; RUN: llc < %s -march=dcpu16 | FileCheck %s
; ModuleID = 'test.c'
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i32 @func(i32 %n, i32 %m) nounwind {
entry:
  %n.addr = alloca i32, align 1
  %m.addr = alloca i32, align 1
  store i32 %n, i32* %n.addr, align 1
  store i32 %m, i32* %m.addr, align 1
  %0 = load i32* %n.addr, align 1
  %1 = load i32* %m.addr, align 1
  %sub = sub nsw i32 %0, %1
  ret i32 %sub
}

; CHECK:        SUB     A, C
; CHECK:        SBX     B, X

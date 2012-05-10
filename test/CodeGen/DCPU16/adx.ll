; RUN: llc < %s -march=dcpu16 | FileCheck %s
; ModuleID = 'test.c'
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @main() nounwind {
entry:
  %retval = alloca i16, align 1
  %a = alloca i32, align 1
  %b = alloca i32, align 1
  %c = alloca i32, align 1
  store i16 0, i16* %retval
  store i32 196607, i32* %a, align 1
  store i32 131071, i32* %b, align 1
  %0 = load i32* %a, align 1
  %1 = load i32* %b, align 1
  %add = add nsw i32 %0, %1
  store i32 %add, i32* %c, align 1
  ret i16 0
}

; CHECK:        ADD     A, PICK 0x{{.}}
; CHECK:        ADX     B, PICK 0x{{.}}


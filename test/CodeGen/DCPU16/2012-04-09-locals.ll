; XFAIL: *
; RUN: llc < %s -O0 -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:8:8-i16:16:16-i32:16:32-i64:64:64-n8:16"
target triple = "dcpu16"

define i16 @f(i16 %x) nounwind {
entry:
  %x.addr = alloca i16
  store i16 %x, i16* %x.addr
  %0 = load i16* %x.addr
  %add = add nsw i16 %0, 3
  ret i16 %add
}
; CHECK: :f
; CHECK: ADD A, 3


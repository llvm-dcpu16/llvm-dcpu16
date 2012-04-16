; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:32-s0:16:16-n16"
target triple = "dcpu16"

define i16 @sum2(i16 %a, i16 %b) nounwind {
entry:
  %a.addr = alloca i16
  %b.addr = alloca i16
  store i16 %a, i16* %a.addr
  store i16 %b, i16* %b.addr
  %0 = load i16* %a.addr
  %1 = load i16* %b.addr
  %add = add nsw i16 %0, %1
  ret i16 %add
}
; CHECK: :sum2
; CHECK: {{ADD ., \[0x[0-9a-f]\+.\]}}

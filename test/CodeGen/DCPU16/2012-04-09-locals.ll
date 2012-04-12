; RUN: llc < %s -march=dcpu16 | FileCheck %s
; RUN: llc < %s -O0 -march=dcpu16 | FileCheck %s -check-prefix=CHECK-O0
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
; CHECK: ADD A, 0x3

; CHECKO0: :f
; CHECK-O0: SET B, A
; CHECK-O0: ADD B, 0x3
; CHECK-O0: SET A, B


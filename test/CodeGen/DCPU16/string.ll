; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

@bar = global [2 x i16] [i16 65, i16 0], align 1
; CHECK: :bar
; CHECK: .short 65
; CHECK: .short 0
; CHECK-NOT: .zero

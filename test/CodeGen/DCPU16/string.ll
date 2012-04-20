; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8-s0:8:8-n16-B16"
target triple = "dcpu16"

@bar = global [2 x i16] [i16 65, i16 0], align 1
; CHECK: :bar
; CHECK: .short 65
; CHECK: .short 0
; CHECK-NOT: .zero

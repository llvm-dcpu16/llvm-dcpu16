; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

@static_int = internal unnamed_addr global i16 0, align 1
@global_int = common global i16 0, align 1

define void @set_val(i16 %val) nounwind {
entry:
  store i16 %val, i16* @static_int, align 1
  store i16 %val, i16* @global_int, align 1
  ret void
}

define void @get_val(i16* nocapture %global_val, i16* nocapture %static_val) nounwind {
entry:
  %0 = load i16* @static_int, align 1
  store i16 %0, i16* %static_val, align 1
  %1 = load i16* @global_int, align 1
  store i16 %1, i16* %global_val, align 1
  ret void
}

; CHECK: .lcomm static_int,1
; CHECK: .comm  global_int,1

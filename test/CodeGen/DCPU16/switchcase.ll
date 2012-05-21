; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @switchcase(i16 %c) nounwind readnone {
entry:
  %and = and i16 %c, 3
  switch i16 %and, label %sw.epilog [
    i16 0, label %sw.bb
    i16 1, label %sw.bb1
    i16 2, label %sw.bb2
    i16 3, label %sw.bb3
  ]

sw.bb:                                            ; preds = %entry
  br label %sw.epilog

sw.bb1:                                           ; preds = %entry
  %shr = ashr i16 %c, 8
  %sub = sub nsw i16 0, %shr
  br label %sw.epilog

sw.bb2:                                           ; preds = %entry
  %shl = shl i16 %c, 8
  br label %sw.epilog

sw.bb3:                                           ; preds = %entry
  %mul = shl nsw i16 %c, 1
  br label %sw.epilog

sw.epilog:                                        ; preds = %entry, %sw.bb3, %sw.bb2, %sw.bb1, %sw.bb
  %x.0 = phi i16 [ 0, %entry ], [ %mul, %sw.bb3 ], [ %shl, %sw.bb2 ], [ %sub, %sw.bb1 ], [ %c, %sw.bb ]
  ret i16 %x.0
}
; just check that it compiles and that a jumptable gets generated
; CHECK: :switchcase
; CHECK: :.LJTI0_0
; CHECK: .byte .LBB0_5
; CHECK: .byte .LBB0_2
; CHECK: .byte .LBB0_3
; CHECK: .byte .LBB0_4

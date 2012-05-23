; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define void @storei32(i32* nocapture %a, i32 %b) nounwind {
entry:
  store i32 %b, i32* %a, align 1, !tbaa !0
  ret void
}

; CHECK: SET [A+0x1], C
; CHECK: SET [A], B

define i32 @loadi32(i32* nocapture %a) nounwind readonly {
entry:
  %0 = load i32* %a, align 1, !tbaa !0
  ret i32 %0
}

!0 = metadata !{metadata !"int", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA"}

; CHECK: SET C, [A]
; CHECK: SET B, [A+0x1]

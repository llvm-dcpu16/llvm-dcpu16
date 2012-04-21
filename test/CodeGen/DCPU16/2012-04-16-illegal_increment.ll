; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define void @mul_by_17(i16* nocapture %as, i16 %size_a) nounwind {
entry:
  %cmp1 = icmp eq i16 %size_a, 0
  br i1 %cmp1, label %for.end, label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.02 = phi i16 [ %inc, %for.body ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i16* %as, i16 %i.02
  %0 = load i16* %arrayidx, align 2, !tbaa !0
  %mul = mul i16 %0, 17
  store i16 %mul, i16* %arrayidx, align 2, !tbaa !0
  %inc = add i16 %i.02, 1
  %exitcond = icmp eq i16 %inc, %size_a
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body, %entry
  ret void
}

!0 = metadata !{metadata !"int", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA", null}

; CHECK: :mul_by_17
; CHECK: MUL [A], 0x11
; CHECK-NOT: SET {{.}}, @{{.}}+

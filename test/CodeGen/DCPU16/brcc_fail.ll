; RUN: llc -march=dcpu16 < %s | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @fib(i16 %n) nounwind readnone {
entry:
  %cmp1 = icmp sgt i16 %n, 0
  br i1 %cmp1, label %for.body, label %for.end

for.body:                                         ; preds = %entry, %for.body
  %i.04 = phi i16 [ %inc, %for.body ], [ 0, %entry ]
  %cur.03 = phi i16 [ %add, %for.body ], [ 1, %entry ]
  %prev.02 = phi i16 [ %cur.03, %for.body ], [ 1, %entry ]
  %add = add nsw i16 %cur.03, %prev.02
  %inc = add nsw i16 %i.04, 1
  %exitcond = icmp eq i16 %inc, %n
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body, %entry
  %cur.0.lcssa = phi i16 [ 1, %entry ], [ %add, %for.body ]
  ret i16 %cur.0.lcssa
}
; CHECK: :fib
; CHECK: IFU B, 0x1

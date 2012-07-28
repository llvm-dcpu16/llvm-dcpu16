; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define void @duplicate_branch(i16 %a, i16 %b, i16 %c) nounwind {
entry:
  %cmp = icmp eq i16 %a, %b
  br i1 %cmp, label %return, label %if.else

if.else:                                          ; preds = %entry
  %cmp1 = icmp slt i16 %a, %b
  br i1 %cmp1, label %if.then2, label %if.else3

if.then2:                                         ; preds = %if.else
  %div = sdiv i16 %c, 10
  br label %if.end4

if.else3:                                         ; preds = %if.else
  %mul = mul nsw i16 %c, 10
  br label %if.end4

if.end4:                                          ; preds = %if.then2, %if.else3
  %c.addr.0 = phi i16 [ %div, %if.then2 ], [ %mul, %if.else3 ]
  tail call void @foo(i16 %c.addr.0) nounwind
  br label %return

return:                                           ; preds = %entry, %if.end4
  ret void
}
; CHECK: :duplicate_branch
; CHECK: IFE A, B
; CHECK: SET PC, .LBB0_5
; CHECK-NOT: IFE A, B
; CHECK: IFA A, B
; CHECK: SET PC, .LBB0_3

declare void @foo(i16)

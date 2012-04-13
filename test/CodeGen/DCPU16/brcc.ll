; XFAIL: *
; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:8:8-i16:16:16-i32:16:32-i64:64:64-n8:16"
target triple = "dcpu16"

define i16 @simplebranch_le(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp sgt i16 %x, %y
  br i1 %cmp, label %if.else, label %if.then

if.then:                                          ; preds = %entry
  %mul = mul nsw i16 %z, 17
  br label %return

if.else:                                          ; preds = %entry
  %add = add nsw i16 %z, 2
  br label %return

return:                                           ; preds = %if.else, %if.then
  %retval.0 = phi i16 [ %mul, %if.then ], [ %add, %if.else ]
  ret i16 %retval.0
}
; CHECK: :simplebranch_le
; CHECK: IFG A, B
; CHECK: SET PC, .LBB0_2

define i16 @simplebranch_l(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp slt i16 %x, %y
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %mul = mul nsw i16 %z, 17
  br label %return

if.else:                                          ; preds = %entry
  %add = add nsw i16 %z, 2
  br label %return

return:                                           ; preds = %if.else, %if.then
  %retval.0 = phi i16 [ %mul, %if.then ], [ %add, %if.else ]
  ret i16 %retval.0
}
; CHECK: :simplebranch_l
; CHECK: IFE A, B
; CHECK: SET PC, .LBB1_2
; CHECK: IFG A, B
; CHECK: SET PC, .LBB1_2

define i16 @simplebranch_ge(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp slt i16 %x, %y
  br i1 %cmp, label %if.else, label %if.then

if.then:                                          ; preds = %entry
  %mul = mul nsw i16 %z, 17
  br label %return

if.else:                                          ; preds = %entry
  %add = add nsw i16 %z, 2
  br label %return

return:                                           ; preds = %if.else, %if.then
  %retval.0 = phi i16 [ %mul, %if.then ], [ %add, %if.else ]
  ret i16 %retval.0
}
; CHECK: :simplebranch_ge
; CHECK: IFG B, A
; CHECK: SET PC, .LBB2_2

define i16 @simplebranch_g(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp sgt i16 %x, %y
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %mul = mul nsw i16 %z, 17
  br label %return

if.else:                                          ; preds = %entry
  %add = add nsw i16 %z, 2
  br label %return

return:                                           ; preds = %if.else, %if.then
  %retval.0 = phi i16 [ %mul, %if.then ], [ %add, %if.else ]
  ret i16 %retval.0
}
; CHECK: :simplebranch_g
; CHECK: IFE A, B
; CHECK: SET PC, .LBB3_2
; CHECK: IFG B, A
; CHECK: SET PC, .LBB3_2

define i16 @simplebranch_e(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp eq i16 %x, %y
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %mul = mul nsw i16 %z, 17
  br label %return

if.else:                                          ; preds = %entry
  %add = add nsw i16 %z, 2
  br label %return

return:                                           ; preds = %if.else, %if.then
  %retval.0 = phi i16 [ %mul, %if.then ], [ %add, %if.else ]
  ret i16 %retval.0
}
; CHECK: :simplebranch_e
; CHECK: IFN A, B
; CHECK: SET PC, .LBB4_2

define i16 @simplebranch_ne(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp eq i16 %x, %y
  br i1 %cmp, label %if.else, label %if.then

if.then:                                          ; preds = %entry
  %mul = mul nsw i16 %z, 17
  br label %return

if.else:                                          ; preds = %entry
  %add = add nsw i16 %z, 2
  br label %return

return:                                           ; preds = %if.else, %if.then
  %retval.0 = phi i16 [ %mul, %if.then ], [ %add, %if.else ]
  ret i16 %retval.0
}
; CHECK: :simplebranch_ne
; CHECK: IFE A, B
; CHECK: SET PC, .LBB5_2

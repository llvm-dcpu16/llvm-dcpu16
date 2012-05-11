; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
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
; CHECK: IFE A, B
; CHECK: SET PC, .LBB0_1
; CHECK: IFU A, B
; CHECK: SET PC, .LBB0_1


define i16 @simplebranch_ule(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp ugt i16 %x, %y
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
; CHECK: :simplebranch_ule
; CHECK: IFE A, B
; CHECK: SET PC, .LBB1_1
; CHECK: IFL A, B
; CHECK: SET PC, .LBB1_1

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
; CHECK: SET PC, .LBB2_2
; CHECK: IFA A, B
; CHECK: SET PC, .LBB2_2

define i16 @simplebranch_ul(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp ult i16 %x, %y
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
; CHECK: :simplebranch_ul
; CHECK: IFE A, B
; CHECK: SET PC, .LBB3_2
; CHECK: IFG A, B
; CHECK: SET PC, .LBB3_2

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
; CHECK: IFE A, B
; CHECK: SET PC, .LBB4_1
; CHECK: IFA A, B
; CHECK: SET PC, .LBB4_1

define i16 @simplebranch_uge(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp ult i16 %x, %y
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
; CHECK: :simplebranch_uge
; CHECK: IFE A, B
; CHECK: SET PC, .LBB5_1
; CHECK: IFG A, B
; CHECK: SET PC, .LBB5_1

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
; CHECK: SET PC, .LBB6_2
; CHECK: IFU A, B
; CHECK: SET PC, .LBB6_2

define i16 @simplebranch_ug(i16 %x, i16 %y, i16 %z) nounwind readnone {
entry:
  %cmp = icmp ugt i16 %x, %y
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
; CHECK: :simplebranch_ug
; CHECK: IFE A, B
; CHECK: SET PC, .LBB7_2
; CHECK: IFL A, B
; CHECK: SET PC, .LBB7_2

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
; CHECK: SET PC, .LBB8_2

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
; CHECK: IFN A, B
; CHECK: SET PC, .LBB9_1

define i16 @imm_branch(i16 %a, i16 %b) nounwind readnone {
entry:
  %cmp = icmp slt i16 %a, 10
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %add = add i16 %b, 10
  br label %return

if.else:                                          ; preds = %entry
  %cmp1 = icmp sgt i16 %a, 20
  br i1 %cmp1, label %if.then2, label %if.else3

if.then2:                                         ; preds = %if.else
  %mul = mul i16 %b, 17
  br label %return

if.else3:                                         ; preds = %if.else
  %div = udiv i16 %b, 5
  br label %return

return:                                           ; preds = %if.else3, %if.then2, %if.then
  %retval.0 = phi i16 [ %add, %if.then ], [ %mul, %if.then2 ], [ %div, %if.else3 ]
  ret i16 %retval.0
}
; CHECK: :imm_branch
; CHECK: IFA A, 0x9
; CHECK: ADD B, 0xa
; CHECK: IFU A, 0x15
; CHECK: MUL B, 0x11
; CHECK: DIV B, 0x5

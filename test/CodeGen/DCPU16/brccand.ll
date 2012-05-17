; RUN: llc < %s -march=dcpu16 -O0 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @brccand_nested() nounwind {
entry:
  %retval = alloca i16, align 1
  %a = alloca i16, align 1
  %b = alloca i16, align 1
  store i16 1, i16* %a, align 1
  store i16 2, i16* %b, align 1
  %0 = load i16* %a, align 1
  %1 = load i16* %b, align 1
  %and = and i16 %0, %1
  %cmp = icmp eq i16 %and, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %2 = load i16* %b, align 1
  %3 = load i16* %a, align 1
  %and1 = and i16 %2, %3
  %cmp2 = icmp ne i16 %and1, 0
  br i1 %cmp2, label %if.then3, label %if.else

if.then3:                                         ; preds = %if.then
  store i16 2, i16* %retval
  br label %return

if.else:                                          ; preds = %if.then
  store i16 1, i16* %retval
  br label %return

if.end:                                           ; preds = %entry
  store i16 0, i16* %retval
  br label %return

return:                                           ; preds = %if.end, %if.else, %if.then3
  %4 = load i16* %retval
  ret i16 %4
}

; CHECK: :brccand_nested
; CHECK: SUB SP, 0x3
; CHECK: SET PICK 0x1, 0x1
; CHECK: SET PEEK, 0x2
; CHECK: SET A, PICK 0x1
; CHECK: IFB A, 0x2
; CHECK: SET PC, .LBB0_4
; CHECK: SET PC, .LBB0_1
; CHECK: :.LBB0_1
; CHECK: SET A, PEEK
; CHECK: SET B, PICK 0x1
; CHECK: IFC A, B
; CHECK: SET PC, .LBB0_3
; CHECK: SET PC, .LBB0_2
; CHECK: :.LBB0_2
; CHECK: SET PICK 0x2, 0x2
; CHECK: SET PC, .LBB0_5
; CHECK: :.LBB0_3
; CHECK: SET PICK 0x2, 0x1
; CHECK: SET PC, .LBB0_5
; CHECK: :.LBB0_4
; CHECK: SET PICK 0x2, 0x0
; CHECK: :.LBB0_5
; CHECK: SET A, PICK 0x2
; CHECK: ADD SP, 0x3
; CHECK: SET PC, POP

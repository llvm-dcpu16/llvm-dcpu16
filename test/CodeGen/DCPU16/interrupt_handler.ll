; RUN: llc -march=dcpu16 < %s | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

@message_sum = global i16 0, align 1
@llvm.used = appending global [1 x i8*] [i8* bitcast (void (i16)* @handle_interrupt to i8*)], section "llvm.metadata"

define dcpu16_intrcc void @handle_interrupt(i16 %msg) nounwind noinline {
entry:
  %0 = load i16* @message_sum, align 1, !tbaa !0
  %add = add nsw i16 %0, %msg
  store i16 %add, i16* @message_sum, align 1, !tbaa !0
  ret void
}

!0 = metadata !{metadata !"int", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA", null}
; CHECK: :handle_interrupt
; CHECK: SET PUSH, EX
; CHECK: ADD [message_sum], A
; CHECK: SET EX, POP
; CHECK: RFI

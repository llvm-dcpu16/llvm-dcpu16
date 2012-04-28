; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define void @clear_keyboard_buffer(i16 %device_id) nounwind {
entry:
  tail call void asm sideeffect "SET A, 0", "~{A}"() nounwind
  tail call void asm sideeffect "HWI $0", "r"(i16 %device_id) nounwind
  ret void
}
; CHECK: :clear_keyboard_buffer
; CHECK: SET B, A
; CHECK: SET A, 0
; CHECK: HWI B

define void @register_tango(i16 %in, i16* %out) nounwind {
entry:
  tail call void asm sideeffect "SET $0, $1", "=*m,{B}"(i16* %out, i16 %in) nounwind
  ret void
}
; CHECK: :register_tango
; CHECK: SET C, B
; CHECK: SET B, A
; CHECK: SET [C], B

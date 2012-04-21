; RUN: llc -march=dcpu16 < %s | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define i16 @mov(i16 %a, i16 %b) nounwind {
; CHECK: :mov
; CHECK: SET A, B
	ret i16 %b
}

define i16 @add(i16 %a, i16 %b) nounwind {
; CHECK: :add
; CHECK: ADD A, B
	%1 = add i16 %a, %b
	ret i16 %1
}

define i16 @and(i16 %a, i16 %b) nounwind {
; CHECK: :and
; CHECK: AND A, B
	%1 = and i16 %a, %b
	ret i16 %1
}

define i16 @bor(i16 %a, i16 %b) nounwind {
; CHECK: :bor
; CHECK: BOR A, B
	%1 = or i16 %a, %b
	ret i16 %1
}

define i16 @xor(i16 %a, i16 %b) nounwind {
; CHECK: :xor
; CHECK: XOR A, B
	%1 = xor i16 %a, %b
	ret i16 %1
}

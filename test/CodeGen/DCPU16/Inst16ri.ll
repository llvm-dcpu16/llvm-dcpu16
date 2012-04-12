; RUN: llc -march=dcpu16 < %s | FileCheck %s
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8"
target triple = "dcpu16"

define i16 @mov() nounwind {
; CHECK: :mov
; CHECK: SET A, 0x1
	ret i16 1
}

define i16 @add(i16 %a, i16 %b) nounwind {
; CHECK: :add
; CHECK: ADD A, 0x1
	%1 = add i16 %a, 1
	ret i16 %1
}

define i16 @and(i16 %a, i16 %b) nounwind {
; CHECK: :and
; CHECK: AND A, 0x1
	%1 = and i16 %a, 1
	ret i16 %1
}

define i16 @bor(i16 %a, i16 %b) nounwind {
; CHECK: :bor
; CHECK: BOR A, 0x1
	%1 = or i16 %a, 1
	ret i16 %1
}

define i16 @xor(i16 %a, i16 %b) nounwind {
; CHECK: :xor
; CHECK: XOR A, 0x1
	%1 = xor i16 %a, 1
	ret i16 %1
}

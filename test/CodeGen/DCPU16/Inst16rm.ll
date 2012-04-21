; RUN: llc -march=dcpu16 < %s | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"
@foo = common global i16 0, align 2

define i16 @add(i16 %a) nounwind {
; CHECK: :add
; CHECK: ADD A, [foo]
	%1 = load i16* @foo
	%2 = add i16 %a, %1
	ret i16 %2
}

define i16 @and(i16 %a) nounwind {
; CHECK: :and
; CHECK: AND A, [foo]
	%1 = load i16* @foo
	%2 = and i16 %a, %1
	ret i16 %2
}

define i16 @bis(i16 %a) nounwind {
; CHECK: :bis
; CHECK: BOR A, [foo]
	%1 = load i16* @foo
	%2 = or i16 %a, %1
	ret i16 %2
}

define i16 @xor(i16 %a) nounwind {
; CHECK: :xor
; CHECK: XOR A, [foo]
	%1 = load i16* @foo
	%2 = xor i16 %a, %1
	ret i16 %2
}


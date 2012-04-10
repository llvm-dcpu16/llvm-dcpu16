; RUN: llc -march=dcpu16 < %s | FileCheck %s
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8"
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


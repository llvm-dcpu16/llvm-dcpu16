; RUN: llc -march=dcpu16 < %s | FileCheck %s

target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8"
target triple = "dcpu16"
@foo = common global i16 0, align 2

define void @mov() nounwind {
; CHECK: :mov
; CHECK: SET [foo], 2
	store i16 2, i16 * @foo
	ret void
}

define void @add() nounwind {
; CHECK: :add
; CHECK: ADD [foo], 2
	%1 = load i16* @foo
	%2 = add i16 %1, 2
	store i16 %2, i16 * @foo
	ret void
}

define void @and() nounwind {
; CHECK: :and
; CHECK: AND [foo], 2
	%1 = load i16* @foo
	%2 = and i16 %1, 2
	store i16 %2, i16 * @foo
	ret void
}

define void @bor() nounwind {
; CHECK: :bor
; CHECK: BOR [foo], 2
	%1 = load i16* @foo
	%2 = or i16 %1, 2
	store i16 %2, i16 * @foo
	ret void
}

define void @xor() nounwind {
; CHECK: :xor
; CHECK: XOR [foo], 2
	%1 = load i16* @foo
	%2 = xor i16 %1, 2
	store i16 %2, i16 * @foo
	ret void
}

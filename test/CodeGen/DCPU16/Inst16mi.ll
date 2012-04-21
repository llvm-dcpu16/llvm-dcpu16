; RUN: llc -march=dcpu16 < %s | FileCheck %s

target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"
@foo = common global i16 0, align 2

define void @mov() nounwind {
; CHECK: :mov
; CHECK: SET [foo], 0x2
	store i16 2, i16 * @foo
	ret void
}

define void @add() nounwind {
; CHECK: :add
; CHECK: ADD [foo], 0x2
	%1 = load i16* @foo
	%2 = add i16 %1, 2
	store i16 %2, i16 * @foo
	ret void
}

define void @and() nounwind {
; CHECK: :and
; CHECK: AND [foo], 0x2
	%1 = load i16* @foo
	%2 = and i16 %1, 2
	store i16 %2, i16 * @foo
	ret void
}

define void @bor() nounwind {
; CHECK: :bor
; CHECK: BOR [foo], 0x2
	%1 = load i16* @foo
	%2 = or i16 %1, 2
	store i16 %2, i16 * @foo
	ret void
}

define void @xor() nounwind {
; CHECK: :xor
; CHECK: XOR [foo], 0x2
	%1 = load i16* @foo
	%2 = xor i16 %1, 2
	store i16 %2, i16 * @foo
	ret void
}

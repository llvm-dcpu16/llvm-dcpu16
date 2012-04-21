; RUN: llc -march=dcpu16 < %s | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"
@foo = common global i16 0, align 2

define void @mov(i16 %a) nounwind {
; CHECK: :mov
; CHECK: SET [foo], A
	store i16 %a, i16* @foo
	ret void
}

define void @add(i16 %a) nounwind {
; CHECK: :add
; CHECK: ADD [foo], A
	%1 = load i16* @foo
	%2 = add i16 %a, %1
	store i16 %2, i16* @foo
	ret void
}

define void @and(i16 %a) nounwind {
; CHECK: :and
; CHECK: AND [foo], A
	%1 = load i16* @foo
	%2 = and i16 %a, %1
	store i16 %2, i16* @foo
	ret void
}

define void @bor(i16 %a) nounwind {
; CHECK: :bor
; CHECK: BOR [foo], A
	%1 = load i16* @foo
	%2 = or i16 %a, %1
	store i16 %2, i16* @foo
	ret void
}

define void @xor(i16 %a) nounwind {
; CHECK: :xor
; CHECK: XOR [foo], A
	%1 = load i16* @foo
	%2 = xor i16 %a, %1
	store i16 %2, i16* @foo
	ret void
}


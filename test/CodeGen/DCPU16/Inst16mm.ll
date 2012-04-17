; RUN: llc -march=dcpu16 -combiner-alias-analysis < %s | FileCheck %s
target datalayout = "e-p:16:8:8-i8:8:8-i16:8:8-i32:8:8-s0:8:8-n16"
target triple = "dcpu16"
@foo = common global i16 0, align 2
@bar = common global i16 0, align 2

define void @mov() nounwind {
; CHECK: :mov
; CHECK: SET [foo], [bar]
        %1 = load i16* @bar
        store i16 %1, i16* @foo
        ret void
}

define void @add() nounwind {
; CHECK: :add
; CHECK: ADD [foo], [bar]
	%1 = load i16* @bar
	%2 = load i16* @foo
	%3 = add i16 %2, %1
	store i16 %3, i16* @foo
	ret void
}

define void @and() nounwind {
; CHECK: :and
; CHECK: AND [foo], [bar]
	%1 = load i16* @bar
	%2 = load i16* @foo
	%3 = and i16 %2, %1
	store i16 %3, i16* @foo
	ret void
}

define void @bor() nounwind {
; CHECK: :bor
; CHECK: BOR [foo], [bar]
	%1 = load i16* @bar
	%2 = load i16* @foo
	%3 = or i16 %2, %1
	store i16 %3, i16* @foo
	ret void
}

define void @xor() nounwind {
; CHECK: :xor
; CHECK: XOR [foo], [bar]
	%1 = load i16* @bar
	%2 = load i16* @foo
	%3 = xor i16 %2, %1
	store i16 %3, i16* @foo
	ret void
}

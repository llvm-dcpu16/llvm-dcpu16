; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

define void @am1(i16* %a, i16 %x) nounwind {
	%1 = load i16* %a
	%2 = or i16 %x, %1
	store i16 %2, i16* %a
	ret void
}
; CHECK: :am1
; CHECK:		BOR     [A], B

@foo = external global i16

define void @am2(i16 %x) nounwind {
	%1 = load volatile i16* inttoptr(i16 32 to i16*)
	%2 = or i16 %x, %1
	store volatile i16 %2, i16* inttoptr(i16 32 to i16*)
	ret void
}
; CHECK: :am2
; CHECK:		BOR     [0x20], A

define void @am3(i16* %a, i16 %x) readonly {
	%1 = getelementptr inbounds i16* %a, i16 2
	%2 = load i16* %1
	%3 = or i16 %x, %2
	store i16 %3, i16* %1
	ret void
}
; CHECK: :am3
; CHECK:		BOR     [A+0x2], B



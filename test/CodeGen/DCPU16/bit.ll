; RUN: llc < %s -march=dcpu16 | FileCheck %s
target datalayout = "e-p:16:16:16-i1:8:8-i8:8:8-i16:16:16-i32:16:32"
target triple = "dcpu16"

@foo16 = external global i16
@bar16 = external global i16

define i16 @bitwrr(i16 %a, i16 %b) nounwind {
	%t1 = and i16 %a, %b
	%t2 = icmp ne i16 %t1, 0
	%t3 = zext i1 %t2 to i16
	ret i16 %t3
}
; CHECK: :bitwrr
; CHECK: IFN A, B ; The Notch order

define i16 @bitwri(i16 %a) nounwind {
	%t1 = and i16 %a, 4080
	%t2 = icmp ne i16 %t1, 0
	%t3 = zext i1 %t2 to i16
	ret i16 %t3
}
; CHECK: :bitwri
; CHECK: IFN A, 4080

define i16 @bitwir(i16 %a) nounwind {
	%t1 = and i16 4080, %a
	%t2 = icmp ne i16 %t1, 0
	%t3 = zext i1 %t2 to i16
	ret i16 %t3
}
; CHECK: :bitwir
; CHECK: IFN A, 4080

define i16 @bitwmi() nounwind {
	%t1 = load i16* @foo16
	%t2 = and i16 %t1, 4080
	%t3 = icmp ne i16 %t2, 0
	%t4 = zext i1 %t3 to i16
	ret i16 %t4
}
; CHECK: :bitwmi
; CHECK: IFN [foo16], 4080

define i16 @bitwim() nounwind {
	%t1 = load i16* @foo16
	%t2 = and i16 4080, %t1
	%t3 = icmp ne i16 %t2, 0
	%t4 = zext i1 %t3 to i16
	ret i16 %t4
}
; CHECK: :bitwim
; CHECK: IFN [foo16], 4080

define i16 @bitwrm(i16 %a) nounwind {
	%t1 = load i16* @foo16
	%t2 = and i16 %a, %t1
	%t3 = icmp ne i16 %t2, 0
	%t4 = zext i1 %t3 to i16
	ret i16 %t4
}
; CHECK: :bitwrm
; CHECK: IFN A, [foo16]

define i16 @bitwmr(i16 %a) nounwind {
	%t1 = load i16* @foo16
	%t2 = and i16 %t1, %a
	%t3 = icmp ne i16 %t2, 0
	%t4 = zext i1 %t3 to i16
	ret i16 %t4
}
; CHECK: :bitwmr
; CHECK: IFN [foo16], A

define i16 @bitwmm() nounwind {
	%t1 = load i16* @foo16
	%t2 = load i16* @bar16
	%t3 = and i16 %t1, %t2
	%t4 = icmp ne i16 %t3, 0
	%t5 = zext i1 %t4 to i16
	ret i16 %t5
}
; CHECK: :bitwmm
; CHECK: IFN [foo16], [bar16]


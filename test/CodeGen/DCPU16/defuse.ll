; RUN: llc -verify-machineinstrs < %s
; Check complex expression against *** Bad machine code: Explicit definition marked as use ***
target datalayout = "e-p:16:16:16-i8:16:16-i16:16:16-i32:16:16-s0:16:16-n16"
target triple = "dcpu16"

@func1.buf = private unnamed_addr constant [5 x i16] [i16 1, i16 2, i16 3, i16 4, i16 5], align 1

define i16 @func1(i16 %a) nounwind {
entry:
  %buf = alloca [5 x i16], align 1
  %0 = bitcast [5 x i16]* %buf to i8*
  call void @llvm.memcpy.p0i8.p0i8.i16(i8* %0, i8* bitcast ([5 x i16]* @func1.buf to i8*), i16 5, i32 1, i1 false)
  %arrayidx = getelementptr inbounds [5 x i16]* %buf, i16 0, i16 0
  %call = call i16 @func2(i16 1) nounwind
  store i16 %a, i16* %arrayidx, align 1, !tbaa !0
  %call3 = call i16 @func2(i16 %a) nounwind
  %xor = xor i16 %call3, %a
  %arrayidx.1 = getelementptr inbounds [5 x i16]* %buf, i16 0, i16 1
  %call.1 = call i16 @func2(i16 770) nounwind
  %add.1 = add nsw i16 %call.1, %call
  %mul.1 = mul nsw i16 %xor, 770
  store i16 %mul.1, i16* %arrayidx.1, align 1, !tbaa !0
  %call3.1 = call i16 @func2(i16 %mul.1) nounwind
  %xor.1 = xor i16 %call3.1, %xor
  %arrayidx.2 = getelementptr inbounds [5 x i16]* %buf, i16 0, i16 2
  %call.2 = call i16 @func2(i16 1027) nounwind
  %add.2 = add nsw i16 %call.2, %add.1
  %mul.2 = mul nsw i16 %xor.1, 1027
  store i16 %mul.2, i16* %arrayidx.2, align 1, !tbaa !0
  %call3.2 = call i16 @func2(i16 %mul.2) nounwind
  %xor.2 = xor i16 %call3.2, %xor.1
  %arrayidx.3 = getelementptr inbounds [5 x i16]* %buf, i16 0, i16 3
  %call.3 = call i16 @func2(i16 1284) nounwind
  %add.3 = add nsw i16 %call.3, %add.2
  %mul.3 = mul nsw i16 %xor.2, 1284
  store i16 %mul.3, i16* %arrayidx.3, align 1, !tbaa !0
  %call3.3 = call i16 @func2(i16 %mul.3) nounwind
  %xor.3 = xor i16 %call3.3, %xor.2
  %arrayidx.4 = getelementptr inbounds [5 x i16]* %buf, i16 0, i16 4
  %1 = load i16* %arrayidx.4, align 1, !tbaa !0
  %call.4 = call i16 @func2(i16 %1) nounwind
  %add.4 = add nsw i16 %call.4, %add.3
  %mul.4 = mul nsw i16 %1, %xor.3
  %call3.4 = call i16 @func2(i16 %mul.4) nounwind
  %xor.4 = xor i16 %call3.4, %xor.3
  %add4 = add nsw i16 %xor.4, %add.4
  ret i16 %add4
}

declare void @llvm.memcpy.p0i8.p0i8.i16(i8* nocapture, i8* nocapture, i16, i32, i1) nounwind

declare i16 @func2(i16)

!0 = metadata !{metadata !"int", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA"}

//===-- DCPU16InstrInfo.td - DCPU16 Instruction defs -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the DCPU16 instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "DCPU16InstrFormats.td"

//===----------------------------------------------------------------------===//
// Type Constraints.
//===----------------------------------------------------------------------===//
class SDTCisI16<int OpNum> : SDTCisVT<OpNum, i16>;

//===----------------------------------------------------------------------===//
// Type Profiles.
//===----------------------------------------------------------------------===//
def SDT_DCPU16Call         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_DCPU16CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>]>;
def SDT_DCPU16CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;
def SDT_DCPU16Wrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                                  SDTCisPtrTy<0>]>;
def SDT_DCPU16Cmp          : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>]>;
def SDT_DCPU16BrCC         : SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>,
                                                  SDTCisVT<1, i16>]>;
def SDT_DCPU16SelectCC     : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                                                  SDTCisSameAs<1, 2>, 
                                                  SDTCisVT<3, i16>]>;
def SDT_DCPU16Shift        : SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>,
                                                  SDTCisI16<2>]>;

//===----------------------------------------------------------------------===//
// DCPU16 Specific Node Definitions.
//===----------------------------------------------------------------------===//
def DCPU16retflag  : SDNode<"DCPU16ISD::RET_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;
def DCPU16retiflag : SDNode<"DCPU16ISD::RETI_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;

def DCPU16rra     : SDNode<"DCPU16ISD::RRA", SDTIntUnaryOp, []>;
def DCPU16rla     : SDNode<"DCPU16ISD::RLA", SDTIntUnaryOp, []>;
def DCPU16rrc     : SDNode<"DCPU16ISD::RRC", SDTIntUnaryOp, []>;

def DCPU16call    : SDNode<"DCPU16ISD::CALL", SDT_DCPU16Call,
                     [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;
def DCPU16callseq_start :
                 SDNode<"ISD::CALLSEQ_START", SDT_DCPU16CallSeqStart,
                        [SDNPHasChain, SDNPOutGlue]>;
def DCPU16callseq_end :
                 SDNode<"ISD::CALLSEQ_END",   SDT_DCPU16CallSeqEnd,
                        [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def DCPU16Wrapper : SDNode<"DCPU16ISD::Wrapper", SDT_DCPU16Wrapper>;
def DCPU16cmp     : SDNode<"DCPU16ISD::CMP", SDT_DCPU16Cmp, [SDNPOutGlue]>;
def DCPU16brcc    : SDNode<"DCPU16ISD::BR_CC", SDT_DCPU16BrCC,
                            [SDNPHasChain, SDNPInGlue]>;
def DCPU16selectcc: SDNode<"DCPU16ISD::SELECT_CC", SDT_DCPU16SelectCC,
                            [SDNPInGlue]>;
def DCPU16shl     : SDNode<"DCPU16ISD::SHL", SDT_DCPU16Shift, []>;
def DCPU16sra     : SDNode<"DCPU16ISD::SRA", SDT_DCPU16Shift, []>;
def DCPU16srl     : SDNode<"DCPU16ISD::SRL", SDT_DCPU16Shift, []>;

//===----------------------------------------------------------------------===//
// DCPU16 Operand Definitions.
//===----------------------------------------------------------------------===//

// Address operands
def memsrc : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

def memdst : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

// Short jump targets have OtherVT type and are printed as pcrel imm values.
def jmptarget : Operand<OtherVT> {
  let PrintMethod = "printPCRelImmOperand";
}

// Operand for printing out a condition code.
def cc : Operand<i16> {
  let PrintMethod = "printCCOperand";
}

//===----------------------------------------------------------------------===//
// DCPU16 Complex Pattern Definitions.
//===----------------------------------------------------------------------===//

def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], []>;

//===----------------------------------------------------------------------===//
// Pattern Fragments
def and_su : PatFrag<(ops node:$lhs, node:$rhs), (and node:$lhs, node:$rhs), [{
  return N->hasOneUse();
}]>;
//===----------------------------------------------------------------------===//
// Instruction list..

// ADJCALLSTACKDOWN/UP implicitly use/def SP because they may be expanded into
// a stack adjustment and the codegen must know that they may modify the stack
// pointer before prolog-epilog rewriting occurs.
// Pessimistically assume ADJCALLSTACKDOWN / ADJCALLSTACKUP will become
// sub / add which can clobber SRW.
let Defs = [SPW, SRW], Uses = [SPW] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i16imm:$amt),
                              "#ADJCALLSTACKDOWN",
                              [(DCPU16callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "#ADJCALLSTACKUP",
                              [(DCPU16callseq_end timm:$amt1, timm:$amt2)]>;
}

let usesCustomInserter = 1 in {
  def Select16 : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$src2, i16imm:$cc),
                        "# Select16 PSEUDO",
                        [(set GR16:$dst,
                          (DCPU16selectcc GR16:$src, GR16:$src2, imm:$cc))]>;
  let Defs = [SRW] in {
  def Shl16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$cnt),
                        "# Shl16 PSEUDO",
                        [(set GR16:$dst, (DCPU16shl GR16:$src, GR16:$cnt))]>;
  def Sra16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$cnt),
                        "# Sra16 PSEUDO",
                        [(set GR16:$dst, (DCPU16sra GR16:$src, GR16:$cnt))]>;
  def Srl16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$cnt),
                        "# Srl16 PSEUDO",
                        [(set GR16:$dst, (DCPU16srl GR16:$src, GR16:$cnt))]>;
  }
}

let neverHasSideEffects = 1 in
def NOP : Pseudo<(outs), (ins), "nop", []>;

//===----------------------------------------------------------------------===//
//  Control Flow Instructions...
//

// FIXME: Provide proper encoding!
let isReturn = 1, isTerminator = 1, isBarrier = 1 in {
  def RET  : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                     (outs), (ins), "SET PC, POP ; The Notch order",  [(DCPU16retflag)]>;
  def RETI : II16r<0x0, (outs), (ins), "reti", [(DCPU16retiflag)]>;
}

let isBranch = 1, isTerminator = 1 in {

// FIXME: expand opcode & cond field for branches!

// Direct branch
let isBarrier = 1 in {
  // Short branch
  def JMP : CJForm<0, 0, (outs), (ins jmptarget:$dst),
                   "SET\t{PC, $dst} ; The Notch order",
                   [(br bb:$dst)]>;
  let isIndirectBranch = 1 in {
    // Long branches
    def Bi  : I16ri<0, (outs), (ins i16imm:$brdst),
                    "br\t$brdst",
                    [(brind tblockaddress:$brdst)]>;
    def Br  : I16rr<0, (outs), (ins GR16:$brdst),
                    "SET\t{pc, $brdst} ; The Notch order",
                    [(brind GR16:$brdst)]>;
    def Bm  : I16rm<0, (outs), (ins memsrc:$brdst),
                    "SET\t{pc, $brdst} ; The Notch order",
                    [(brind (load addr:$brdst))]>;
  }
}

// Conditional branches
let Uses = [SRW] in
  def JCC : CJForm<0, 0,
                   (outs), (ins jmptarget:$dst, cc:$cc),
                   "$cc $dst ; The Notch order",
                   [(DCPU16brcc bb:$dst, imm:$cc)]>;
} // isBranch, isTerminator

//===----------------------------------------------------------------------===//
//  Call Instructions...
//
let isCall = 1 in
  // All calls clobber the non-callee saved registers. SPW is marked as
  // a use to prevent stack-pointer assignments that appear immediately
  // before calls from potentially appearing dead. Uses for argument
  // registers are added manually.
  let Defs = [R8J, SRW],
      Uses = [SPW] in {
    def CALLi     : II16i<0x0,
                          (outs), (ins i16imm:$dst, variable_ops),
                          "JSR\t$dst ; The Notch order", [(DCPU16call imm:$dst)]>;
    def CALLr     : II16r<0x0,
                          (outs), (ins GR16:$dst, variable_ops),
                          "JSR\t$dst ; The Notch order", [(DCPU16call GR16:$dst)]>;
    def CALLm     : II16m<0x0,
                          (outs), (ins memsrc:$dst, variable_ops),
                          "JSR\t${dst:mem} ; The Notch order", [(DCPU16call (load addr:$dst))]>;
  }


//===----------------------------------------------------------------------===//
//  Miscellaneous Instructions...
//
let Defs = [SPW], Uses = [SPW], neverHasSideEffects=1 in {
let mayLoad = 1 in
def POP16r   : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                       (outs GR16:$reg), (ins), "pop.w\t$reg", []>;

let mayStore = 1 in
def PUSH16r  : II16r<0x0,
                     (outs), (ins GR16:$reg), "push.w\t$reg",[]>;
}

//===----------------------------------------------------------------------===//
// Move Instructions

// FIXME: Provide proper encoding!
let neverHasSideEffects = 1 in {
def MOV16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "SET\t{$dst, $src} ; The Notch order",
                    []>;
}

// FIXME: Provide proper encoding!
let isReMaterializable = 1, isAsCheapAsAMove = 1 in {
def MOV16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins i16imm:$src),
                    "SET\t{$dst, $src} ; The Notch order",
                    [(set GR16:$dst, imm:$src)]>;
}

let canFoldAsLoad = 1, isReMaterializable = 1 in {
def MOV16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins memsrc:$src),
                    "SET\t{$dst, $src} ; The Notch order",
                    [(set GR16:$dst, (load addr:$src))]>;
}

let mayLoad = 1, hasExtraDefRegAllocReq = 1 in {
def MOV16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb), (ins GR16:$base),
                           "SET\t{$dst, @$base+} ; The Notch order", []>;
}

def MOV16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "SET\t{$dst, $src} ; The Notch order",
                    [(store (i16 imm:$src), addr:$dst)]>;

def MOV16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "SET\t{$dst, $src} ; The Notch order",
                    [(store GR16:$src, addr:$dst)]>;

def MOV16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "SET\t{$dst, $src} ; The Notch order",
                    [(store (i16 (load addr:$src)), addr:$dst)]>;

//===----------------------------------------------------------------------===//
// Arithmetic Instructions

let Defs = [SRW] in {

let isCommutable = 1 in { // X = ADD Y, Z  == X = ADD Z, Y
def ADD16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "ADD\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (add GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
}

def ADD16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "ADD\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (add GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1 in {
def ADD16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                          "ADD\t{$dst, @$base+} ; The Notch order", []>;
}


def ADD16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "ADD\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (add GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def ADD16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "ADD\t{$dst, $src} ; The Notch order",
                    [(store (add (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def ADD16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "ADD\t{$dst, $src} ; The Notch order",
                    [(store (add (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def ADD16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "ADD\t{$dst, $src} ; The Notch order",
                    [(store (add (load addr:$dst), 
                                  (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;

let Uses = [SRW] in {

let isCommutable = 1 in { // X = ADDC Y, Z  == X = ADDC Z, Y
def ADC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
} // isCommutable

def ADC16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def ADC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

def ADC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "addc.w\t{$src, $dst}",
                    [(store (adde (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def ADC16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "addc.w\t{$src, $dst}",
                    [(store (adde (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def ADC16mm : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "addc.w\t{$src, $dst}",
                   [(store (adde (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                    (implicit SRW)]>;

} // Uses = [SRW]

let isCommutable = 1 in { // X = AND Y, Z  == X = AND Z, Y
def AND16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "AND\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
}

def AND16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "AND\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def AND16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "AND\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1 in {
def AND16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           "AND\t{@$base+, $dst}", []>;
}

def AND16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "AND\t{$src, $dst}",
                    [(store (and (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def AND16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "AND\t{$src, $dst}",
                    [(store (and (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def AND16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "AND\t{$src, $dst}",
                    [(store (and (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;

let isCommutable = 1 in { // X = OR Y, Z  == X = OR Z, Y
def OR16rr : I16rr<0x0,
                   (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                   "BOR\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, GR16:$src2))]>;
}

def OR16ri : I16ri<0x0,
                   (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                   "BOR\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, imm:$src2))]>;

def OR16rm : I16rm<0x0,
                   (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                   "BOR\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, (load addr:$src2)))]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1 in {
def OR16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "BOR\t{@$base+, $dst}", []>;
}

def OR16mr : I16mr<0x0,
                   (outs), (ins memdst:$dst, GR16:$src),
                   "BOR\t{$src, $dst}",
                   [(store (or (load addr:$dst), GR16:$src), addr:$dst)]>;

def OR16mi : I16mi<0x0,
                   (outs), (ins memdst:$dst, i16imm:$src),
                   "BOR\t{$src, $dst}",
                   [(store (or (load addr:$dst), (i16 imm:$src)), addr:$dst)]>;

def OR16mm : I16mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "BOR\t{$src, $dst}",
                   [(store (or (i16 (load addr:$dst)),
                               (i16 (load addr:$src))), addr:$dst)]>;

// bic does not modify condition codes

def BIC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "bic.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (not GR16:$src2)))]>;

def BIC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "bic.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (not (i16 (load addr:$src2)))))]>;

def BIC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "bic.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), (not GR16:$src)), addr:$dst)]>;

def BIC16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "bic.w\t{$src, $dst}",
                    [(store (and (load addr:$dst),
                                 (not (i16 (load addr:$src)))), addr:$dst)]>;

let isCommutable = 1 in { // X = XOR Y, Z  == X = XOR Z, Y
def XOR16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "XOR\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
}

def XOR16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "XOR\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def XOR16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "XOR\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1 in {
def XOR16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           "XOR\t{@$base+, $dst}", []>;
}

def XOR16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "XOR\t{$src, $dst}",
                    [(store (xor (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def XOR16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "XOR\t{$src, $dst}",
                    [(store (xor (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def XOR16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "XOR\t{$src, $dst}",
                    [(store (xor (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;


def SUB16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "SUB\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (sub GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
def SUB16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "SUB\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (sub GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def SUB16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "SUB\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (sub GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1 in {
def SUB16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "SUB\t{$dst, @$base+} ; The Notch order", []>;
}

def SUB16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "SUB\t{$dst, $src} ; The Notch order",
                    [(store (sub (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def SUB16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "SUB\t{$dst, $src} ; The Notch order",
                    [(store (sub (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def SUB16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "SUB\t{$dst, $src} ; The Notch order",
                    [(store (sub (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;

let Uses = [SRW] in {
def SBC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;

def SBC16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def SBC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

def SBC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def SBC16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def SBC16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst),
                            (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;
} // Uses = [SRW]

// FIXME: memory variant!
def SAR16r1 : II16r<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "rra.w\t$dst",
                    [(set GR16:$dst, (DCPU16rra GR16:$src)),
                     (implicit SRW)]>;

def SHL16r1 : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "rla.w\t$dst",
                    [(set GR16:$dst, (DCPU16rla GR16:$src)),
                     (implicit SRW)]>;

def SAR16r1c : Pseudo<(outs GR16:$dst), (ins GR16:$src),
                      "clrc\n\t"
                      "rrc.w\t$dst",
                      [(set GR16:$dst, (DCPU16rrc GR16:$src)),
                       (implicit SRW)]>;
} // Defs = [SRW]

// FIXME: Memory bitswaps?
def SWPB16r : II16r<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "swpb\t$dst",
                    [(set GR16:$dst, (bswap GR16:$src))]>;

// Integer comparisons
let Defs = [SRW] in {
def CMP16rr : I16rr<0x0,
                    (outs), (ins GR16:$src, GR16:$src2),
		    "SET\tO, 65535 ; The Notch order, cmp {$src2, $src}, start\n"
		    "\tIFE\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 0 ; The Notch order\n"
		    "\tIFG\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 1 ; The Notch order, end",
                    [(DCPU16cmp GR16:$src, GR16:$src2), (implicit SRW)]>;

def CMP16ri : I16ri<0x0,
                    (outs), (ins GR16:$src, i16imm:$src2),
		    "SET\tO, 65535 ; The Notch order, cmp {$src2, $src}, start\n"
		    "\tIFE\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 0 ; The Notch order\n"
		    "\tIFG\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 1 ; The Notch order, end",
                    [(DCPU16cmp GR16:$src, imm:$src2), (implicit SRW)]>;

def CMP16mi : I16mi<0x0,
                    (outs), (ins memsrc:$src, i16imm:$src2),
		    "SET\tO, 65535 ; The Notch order, cmp {$src2, $src}, start\n"
		    "\tIFE\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 0 ; The Notch order\n"
		    "\tIFG\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 1 ; The Notch order, end",
                     [(DCPU16cmp (load addr:$src),
                                 (i16 imm:$src2)), (implicit SRW)]>;

def CMP16rm : I16rm<0x0,
                    (outs), (ins GR16:$src, memsrc:$src2),
      		    "SET\tO, 65535 ; The Notch order, cmp {$src2, $src}, start\n"
		    "\tIFE\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 0 ; The Notch order\n"
		    "\tIFG\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 1 ; The Notch order, end",
                    [(DCPU16cmp GR16:$src, (load addr:$src2)),
                     (implicit SRW)]>;

def CMP16mr : I16mr<0x0,
                    (outs), (ins memsrc:$src, GR16:$src2),
		    "SET\tO, 65535 ; The Notch order, cmp {$src2, $src}, start\n"
		    "\tIFE\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 0 ; The Notch order\n"
		    "\tIFG\t{$src, $src2} ; The Notch order\n"
		    "\tSET\tO, 1 ; The Notch order, end",
                    [(DCPU16cmp (load addr:$src), GR16:$src2), 
                     (implicit SRW)]>;


// BIT TESTS, just sets condition codes
// Note that the C condition is set differently than when using CMP.
let isCommutable = 1 in {
def BIT16rr : I16rr<0x0,
                    (outs), (ins GR16:$src, GR16:$src2),
                    "bit.w\t{$src2, $src}",
                    [(DCPU16cmp (and_su GR16:$src, GR16:$src2), 0),
                     (implicit SRW)]>;
}
def BIT16ri : I16ri<0x0,
                    (outs), (ins GR16:$src, i16imm:$src2),
                    "bit.w\t{$src2, $src}",
                    [(DCPU16cmp (and_su GR16:$src, imm:$src2), 0),
                     (implicit SRW)]>;

def BIT16rm : I16rm<0x0,
                    (outs), (ins GR16:$src, memdst:$src2),
                    "bit.w\t{$src2, $src}",
                    [(DCPU16cmp (and_su GR16:$src,  (load addr:$src2)), 0),
                     (implicit SRW)]>;

def BIT16mr : I16mr<0x0,
                    (outs), (ins memsrc:$src, GR16:$src2),
                    "bit.w\t{$src2, $src}",
                    [(DCPU16cmp (and_su (load addr:$src), GR16:$src2), 0),
                     (implicit SRW)]>;

def BIT16mi : I16mi<0x0,
                    (outs), (ins memsrc:$src, i16imm:$src2),
                    "bit.w\t{$src2, $src}",
                    [(DCPU16cmp (and_su (load addr:$src), (i16 imm:$src2)), 0),
                     (implicit SRW)]>;

def BIT16mm : I16mm<0x0,
                    (outs), (ins memsrc:$src, memsrc:$src2),
                    "bit.w\t{$src2, $src}",
                    [(DCPU16cmp (and_su (i16 (load addr:$src)),
                                        (load addr:$src2)),
                                 0),
                     (implicit SRW)]>;
} // Defs = [SRW]

//===----------------------------------------------------------------------===//
// Non-Instruction Patterns

// GlobalAddress, ExternalSymbol
def : Pat<(i16 (DCPU16Wrapper tglobaladdr:$dst)), (MOV16ri tglobaladdr:$dst)>;
def : Pat<(i16 (DCPU16Wrapper texternalsym:$dst)), (MOV16ri texternalsym:$dst)>;
def : Pat<(i16 (DCPU16Wrapper tblockaddress:$dst)), (MOV16ri tblockaddress:$dst)>;

def : Pat<(add GR16:$src, (DCPU16Wrapper tglobaladdr :$src2)),
          (ADD16ri GR16:$src, tglobaladdr:$src2)>;
def : Pat<(add GR16:$src, (DCPU16Wrapper texternalsym:$src2)),
          (ADD16ri GR16:$src, texternalsym:$src2)>;
def : Pat<(add GR16:$src, (DCPU16Wrapper tblockaddress:$src2)),
          (ADD16ri GR16:$src, tblockaddress:$src2)>;

def : Pat<(store (i16 (DCPU16Wrapper tglobaladdr:$src)), addr:$dst),
          (MOV16mi addr:$dst, tglobaladdr:$src)>;
def : Pat<(store (i16 (DCPU16Wrapper texternalsym:$src)), addr:$dst),
          (MOV16mi addr:$dst, texternalsym:$src)>;
def : Pat<(store (i16 (DCPU16Wrapper tblockaddress:$src)), addr:$dst),
          (MOV16mi addr:$dst, tblockaddress:$src)>;

// calls
def : Pat<(DCPU16call (i16 tglobaladdr:$dst)),
          (CALLi tglobaladdr:$dst)>;
def : Pat<(DCPU16call (i16 texternalsym:$dst)),
          (CALLi texternalsym:$dst)>;

// add and sub always produce carry
def : Pat<(addc GR16:$src, GR16:$src2),
          (ADD16rr GR16:$src, GR16:$src2)>;
def : Pat<(addc GR16:$src, (load addr:$src2)),
          (ADD16rm GR16:$src, addr:$src2)>;
def : Pat<(addc GR16:$src, imm:$src2),
          (ADD16ri GR16:$src, imm:$src2)>;
def : Pat<(store (addc (load addr:$dst), GR16:$src), addr:$dst),
          (ADD16mr addr:$dst, GR16:$src)>;
def : Pat<(store (addc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (ADD16mm addr:$dst, addr:$src)>;

def : Pat<(subc GR16:$src, GR16:$src2),
          (SUB16rr GR16:$src, GR16:$src2)>;
def : Pat<(subc GR16:$src, (load addr:$src2)),
          (SUB16rm GR16:$src, addr:$src2)>;
def : Pat<(subc GR16:$src, imm:$src2),
          (SUB16ri GR16:$src, imm:$src2)>;
def : Pat<(store (subc (load addr:$dst), GR16:$src), addr:$dst),
          (SUB16mr addr:$dst, GR16:$src)>;
def : Pat<(store (subc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (SUB16mm addr:$dst, addr:$src)>;


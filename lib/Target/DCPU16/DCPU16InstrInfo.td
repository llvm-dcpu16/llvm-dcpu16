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
def SDT_DCPU16BrCC         : SDTypeProfile<0, 4, [SDTCisVT<0, i16>,
                                                  SDTCisSameAs<1, 0>,
                                                  SDTCisSameAs<2, 1>,
                                                  SDTCisVT<3, OtherVT>]>;
def SDT_DCPU16SelectCC     : SDTypeProfile<1, 5, [SDTCisSameAs<0, 1>,
                                                  SDTCisSameAs<1, 2>,
                                                  SDTCisSameAs<2, 3>,
                                                  SDTCisSameAs<3, 4>,
                                                  SDTCisSameAs<4, 5>,
                                                  SDTCisVT<5, i16>]>;
def SDT_DCPU16Shift        : SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>,
                                                  SDTCisI16<2>]>;

//===----------------------------------------------------------------------===//
// DCPU16 Specific Node Definitions.
//===----------------------------------------------------------------------===//
def DCPU16retflag  : SDNode<"DCPU16ISD::RET_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;

def DCPU16call    : SDNode<"DCPU16ISD::CALL", SDT_DCPU16Call,
                     [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;
def DCPU16callseq_start :
                 SDNode<"ISD::CALLSEQ_START", SDT_DCPU16CallSeqStart,
                        [SDNPHasChain, SDNPOutGlue]>;
def DCPU16callseq_end :
                 SDNode<"ISD::CALLSEQ_END",   SDT_DCPU16CallSeqEnd,
                        [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def DCPU16Wrapper : SDNode<"DCPU16ISD::Wrapper", SDT_DCPU16Wrapper>;
def DCPU16brcc    : SDNode<"DCPU16ISD::BR_CC", SDT_DCPU16BrCC,
                            [SDNPHasChain]>;
def DCPU16selectcc: SDNode<"DCPU16ISD::SELECT_CC", SDT_DCPU16SelectCC, []>;

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
// sub / add which can clobber RO.
let Defs = [RI, RO], Uses = [RI] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i16imm:$amt),
                              "#ADJCALLSTACKDOWN",
                              [(DCPU16callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "#ADJCALLSTACKUP",
                              [(DCPU16callseq_end timm:$amt1, timm:$amt2)]>;
}

// $dst _can_ be $falseV
let Constraints = "@earlyclobber $dst" in {
  // TODO: add more combinations, in particular memory access
  def Select16rrrr : Pseudo<(outs GR16:$dst),
                  (ins cc:$cc, GR16:$lhs, GR16:$rhs, GR16:$trueV, GR16:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GR16:$dst,
                    (DCPU16selectcc imm:$cc, GR16:$lhs, GR16:$rhs, GR16:$trueV, GR16:$falseV))]>;
  def Select16rirr : Pseudo<(outs GR16:$dst),
                  (ins cc:$cc, GR16:$lhs, i16imm:$rhs, GR16:$trueV, GR16:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GR16:$dst,
                    (DCPU16selectcc imm:$cc, GR16:$lhs, imm:$rhs, GR16:$trueV, GR16:$falseV))]>;
  def Select16irrr : Pseudo<(outs GR16:$dst),
                  (ins cc:$cc, i16imm:$lhs, GR16:$rhs, GR16:$trueV, GR16:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GR16:$dst,
                    (DCPU16selectcc imm:$cc, imm:$lhs, GR16:$rhs, GR16:$trueV, GR16:$falseV))]>;

  def Select16rrii : Pseudo<(outs GR16:$dst),
                  (ins cc:$cc, GR16:$lhs, GR16:$rhs, i16imm:$trueV, i16imm:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GR16:$dst,
                    (DCPU16selectcc imm:$cc, GR16:$lhs, GR16:$rhs, imm:$trueV, imm:$falseV))]>;
  def Select16riii : Pseudo<(outs GR16:$dst),
                  (ins cc:$cc, GR16:$lhs, i16imm:$rhs, i16imm:$trueV, i16imm:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GR16:$dst,
                    (DCPU16selectcc imm:$cc, GR16:$lhs, imm:$rhs, imm:$trueV, imm:$falseV))]>;
  def Select16irii : Pseudo<(outs GR16:$dst),
                  (ins cc:$cc, i16imm:$lhs, GR16:$rhs, i16imm:$trueV, i16imm:$falseV),
                  "SET\t{$dst, $falseV}\n"
                  "\t$cc\t{$lhs, $rhs}\n"
                  "\tSET\t{$dst, $trueV}",
                  [(set GR16:$dst,
                    (DCPU16selectcc imm:$cc, imm:$lhs, GR16:$rhs, imm:$trueV, imm:$falseV))]>;
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
// TODO: add immediate and memory versions
def BR_CC : CJForm<0, 0,
   (outs), (ins cc:$cc, GR16:$lhs, GR16:$rhs, jmptarget:$dst),
   "$cc\t{$lhs, $rhs} ; The Notch order\n"
   "\tSET\t{PC, $dst} ; The Notch order",
   [(DCPU16brcc imm:$cc, GR16:$lhs, GR16:$rhs, bb:$dst)]>;
} // isBranch, isTerminator

//===----------------------------------------------------------------------===//
//  Call Instructions...
//
let isCall = 1 in
  // All calls clobber the non-callee saved registers. RI is marked as
  // a use to prevent stack-pointer assignments that appear immediately
  // before calls from potentially appearing dead. Uses for argument
  // registers are added manually.
  let Defs = [RO],
      Uses = [RI] in {
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
let Defs = [RI], Uses = [RI], neverHasSideEffects=1 in {
let mayLoad = 1 in
def POP16r   : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                       (outs GR16:$reg), (ins), "SET\t{$reg, POP}", []>;

let mayStore = 1 in
def PUSH16r  : II16r<0x0,
                     (outs), (ins GR16:$reg), "SET\t{PUSH, $reg}",[]>;
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

let canFoldAsLoad = 1, isReMaterializable = 1 in {
def MOV16rmi8 : I16rm<0x0,
                    (outs GR16:$dst), (ins memsrc:$src),
                    "SET\t{$dst, $src} ; The Notch order",
                    [(set GR16:$dst, (zextloadi8 addr:$src))]>;
}

let mayLoad = 1, hasExtraDefRegAllocReq = 1, Constraints = "$base = $base_wb" in {
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

let Constraints = "$src = $dst" in {

let Defs = [RO] in {


let Uses = [RO] in {

let isCommutable = 1 in { // X = ADDC Y, Z  == X = ADDC Z, Y
def ADC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, GR16:$src2)),
                     (implicit RO)]>;
} // isCommutable

def ADC16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, imm:$src2)),
                     (implicit RO)]>;

def ADC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, (load addr:$src2))),
                     (implicit RO)]>;

let Constraints = "" in {
def ADC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "addc.w\t{$src, $dst}",
                    [(store (adde (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RO)]>;

def ADC16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "addc.w\t{$src, $dst}",
                    [(store (adde (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RO)]>;

def ADC16mm : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "addc.w\t{$src, $dst}",
                   [(store (adde (load addr:$dst),
                                 (i16 (load addr:$src))), addr:$dst),
                    (implicit RO)]>;
}

} // Uses = [RO]

let isCommutable = 1 in { // X = AND Y, Z  == X = AND Z, Y
def AND16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "AND\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (and GR16:$src, GR16:$src2)),
                     (implicit RO)]>;
}

def AND16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "AND\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (and GR16:$src, imm:$src2)),
                     (implicit RO)]>;

def AND16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "AND\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (and GR16:$src, (load addr:$src2))),
                     (implicit RO)]>;

def AND16rmi8 : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "AND\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (and GR16:$src, (zextloadi8 addr:$src2))),
                     (implicit RO)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1,
Constraints = "$base = $base_wb, $src = $dst" in {
def AND16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           "AND\t{$dst, @$base+} ; The Notch order", []>;
}

let Constraints = "" in {
def AND16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "AND\t{$dst, $src} ; The Notch order",
                    [(store (and (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RO)]>;

def AND16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "AND\t{$dst, $src} ; The Notch order",
                    [(store (and (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RO)]>;

def AND16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "AND\t{$dst, $src} ; The Notch order",
                    [(store (and (load addr:$dst),
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit RO)]>;
}

let isCommutable = 1 in { // X = OR Y, Z  == X = OR Z, Y
def OR16rr : I16rr<0x0,
                   (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                   "BOR\t{$dst, $src2} ; The Notch order",
                   [(set GR16:$dst, (or GR16:$src, GR16:$src2))]>;
}

def OR16ri : I16ri<0x0,
                   (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                   "BOR\t{$dst, $src2} ; The Notch order",
                   [(set GR16:$dst, (or GR16:$src, imm:$src2))]>;

def OR16rm : I16rm<0x0,
                   (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                   "BOR\t{$dst, $src2} ; The Notch order",
                   [(set GR16:$dst, (or GR16:$src, (load addr:$src2)))]>;

def OR16rmi8 : I16rm<0x0,
                   (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                   "BOR\t{$dst, $src2} ; The Notch order",
                   [(set GR16:$dst, (or GR16:$src, (zextloadi8 addr:$src2)))]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1,
Constraints = "$base = $base_wb, $src = $dst" in {
def OR16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "BOR\t{$dst, @$base+} ; The Notch order", []>;
}

let Constraints = "" in {
def OR16mr : I16mr<0x0,
                   (outs), (ins memdst:$dst, GR16:$src),
                   "BOR\t{$dst, $src} ; The Notch order",
                   [(store (or (load addr:$dst), GR16:$src), addr:$dst)]>;

def OR16mi : I16mi<0x0,
                   (outs), (ins memdst:$dst, i16imm:$src),
                   "BOR\t{$dst, $src} ; The Notch order",
                   [(store (or (load addr:$dst), (i16 imm:$src)), addr:$dst)]>;

def OR16mm : I16mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "BOR\t{$dst, $src} ; The Notch order",
                   [(store (or (i16 (load addr:$dst)),
                               (i16 (load addr:$src))), addr:$dst)]>;

}

let isCommutable = 1 in { // X = XOR Y, Z  == X = XOR Z, Y
def XOR16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "XOR\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (xor GR16:$src, GR16:$src2)),
                     (implicit RO)]>;
}

def XOR16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "XOR\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (xor GR16:$src, imm:$src2)),
                     (implicit RO)]>;

def XOR16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "XOR\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (xor GR16:$src, (load addr:$src2))),
                     (implicit RO)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1,
Constraints = "$base = $base_wb, $src = $dst" in {
def XOR16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           "XOR\t{$dst, @$base+} ; The Notch order", []>;
}

let Constraints = "" in {
def XOR16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "XOR\t{$dst, $src} ; The Notch order",
                    [(store (xor (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RO)]>;

def XOR16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "XOR\t{$dst, $src} ; The Notch order",
                    [(store (xor (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RO)]>;

def XOR16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "XOR\t{$dst, $src} ; The Notch order",
                    [(store (xor (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
                     (implicit RO)]>;
}

def SUB16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "SUB\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (sub GR16:$src, GR16:$src2)),
                     (implicit RO)]>;
def SUB16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "SUB\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (sub GR16:$src, imm:$src2)),
                     (implicit RO)]>;

def SUB16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "SUB\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (sub GR16:$src, (load addr:$src2))),
                     (implicit RO)]>;

def SUB16rmi8 : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "SUB\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (sub GR16:$src, (zextloadi8 addr:$src2))),
                     (implicit RO)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1,
Constraints = "$base = $base_wb, $src = $dst" in {
def SUB16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "SUB\t{$dst, @$base+} ; The Notch order", []>;
}

let Constraints = "" in {
def SUB16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "SUB\t{$dst, $src} ; The Notch order",
                    [(store (sub (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RO)]>;

def SUB16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "SUB\t{$dst, $src} ; The Notch order",
                    [(store (sub (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RO)]>;

def SUB16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "SUB\t{$dst, $src} ; The Notch order",
                    [(store (sub (load addr:$dst),
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit RO)]>;
}


def MUL16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "MUL\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (mul GR16:$src, GR16:$src2))]>;

def MUL16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "MUL\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (mul GR16:$src, imm:$src2))]>;

def MUL16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "MUL\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (mul GR16:$src, (load addr:$src2)))]>;

def MUL16rmi8 : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "MUL\t{$dst, $src2} ; The Notch order",
                    [(set GR16:$dst, (mul GR16:$src, (zextloadi8 addr:$src2)))]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1,
Constraints = "$base = $base_wb, $src = $dst" in {
def MUL16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "MUL\t{$dst, @$base+} ; The Notch order", []>;
}

let Constraints = "" in {
def MUL16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "MUL\t{$dst, $src} ; The Notch order",
                    [(store (mul (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RO)]>;

def MUL16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "MUL\t{$dst, $src} ; The Notch order",
                    [(store (mul (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RO)]>;

def MUL16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "MUL\t{$dst, $src} ; The Notch order",
                    [(store (mul (load addr:$dst),
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit RO)]>;
}

let Uses = [RO] in {
def SBC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, GR16:$src2)),
                     (implicit RO)]>;

def SBC16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, imm:$src2)),
                     (implicit RO)]>;

def SBC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, (load addr:$src2))),
                     (implicit RO)]>;

let Constraints = "" in {

def SBC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RO)]>;

def SBC16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RO)]>;

def SBC16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst),
                            (i16 (load addr:$src))), addr:$dst),
                     (implicit RO)]>;
}

} // Uses = [RO]

// TODO: add memory variants
def SRL16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "SHR\t{$src, $src2}",
                    [(set GR16:$dst, (srl GR16:$src, GR16:$src2)),
                     (implicit RO)]>;
def SRL16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "SHR\t{$src, $src2}",
                    [(set GR16:$dst, (srl GR16:$src, imm:$src2)),
                     (implicit RO)]>;

// FIXME: replace this instruction with the correct arrithmetic shift once
// Notch updates the spec
def SRA16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "SHR\t{$src, $src2}",
                    [(set GR16:$dst, (sra GR16:$src, GR16:$src2)),
                     (implicit RO)]>;
def SRA16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "SHR\t{$src, $src2}",
                    [(set GR16:$dst, (sra GR16:$src, imm:$src2)),
                     (implicit RO)]>;

def SHL16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "SHL\t{$src, $src2}",
                    [(set GR16:$dst, (shl GR16:$src, GR16:$src2)),
                     (implicit RO)]>;
def SHL16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "SHL\t{$src, $src2}",
                    [(set GR16:$dst, (shl GR16:$src, imm:$src2)),
                     (implicit RO)]>;

} // Defs = [RO]

} // Constraints = "$src = $dst"

//===----------------------------------------------------------------------===//
// Multiclasses for instructions

multiclass BASIC_RR_IS_COM<bits<4> OpVal, string OpcStr, SDNode OpNode> {
  let Constraints = "$src = $dst", isCommutable = 1 in {
  def rr: I16rr<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    OpcStr#"\t{$dst, $src2}",
                    [(set GR16:$dst, (OpNode GR16:$src, GR16:$src2)),
                     (implicit RO)]>;
  }
}

multiclass BASIC_NORMAL<bits<4> OpVal, string OpcStr, SDNode OpNode> {
  let Constraints = "$src = $dst" in {
  def rm: I16rm<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    OpcStr#"\t{$dst, $src2}",
                    [(set GR16:$dst, (OpNode GR16:$src, (load addr:$src2))),
                     (implicit RO)]>;
  def ri: I16ri<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    OpcStr#"\t{$dst, $src2}",
                    [(set GR16:$dst, (OpNode GR16:$src, imm:$src2)),
                     (implicit RO)]>;
  }
  let Constraints = "" in {
  def mr: I16mr<OpVal,
                    (outs), (ins memdst:$dst, GR16:$src),
                    OpcStr#"\t{$dst, $src}",
                    [(store (OpNode (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RO)]>;
  def mi: I16mi<OpVal,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    OpcStr#"\t{$dst, $src}",
                    [(store (OpNode (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RO)]>;
  def mm: I16mm<OpVal,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    OpcStr#"\t{$dst, $src}",
                    [(store (OpNode (load addr:$dst),
                                  (i16 (load addr:$src))), addr:$dst),
                     (implicit RO)]>;
  }
  
  // FIXME! Wrong zero extend
  let Constraints = "$src = $dst", canFoldAsLoad = 1, isReMaterializable = 1 in {
  def rmi8 : I16rm<OpVal,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
					OpcStr#"\t{$dst, $src}",
                    [(set GR16:$dst, (OpNode GR16:$src, (zextloadi8 addr:$src2))),
                     (implicit RO)]>;
  }  
}

multiclass BASIC_RM_POST<bits<4> OpVal, string OpcStr> {
  let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
    Constraints = "$base = $base_wb, $src = $dst" in {
  
  def rm_POST: IForm16<OpVal, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           OpcStr#"\t{$dst, @$base+}", []>;

  }
}

//===----------------------------------------------------------------------===//
// Instructions

let Defs = [RO] in {
  defm ADD16   : BASIC_RR_IS_COM <0x0,"ADD", add>,  BASIC_NORMAL<0x0, "ADD", add>, BASIC_RM_POST<0x0, "ADD">;

} // Defs = [RO]


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

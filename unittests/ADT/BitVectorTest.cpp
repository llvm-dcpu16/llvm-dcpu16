//===- llvm/unittest/ADT/BitVectorTest.cpp - BitVector tests --------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

// Some of these tests fail on PowerPC for unknown reasons.
#ifndef __ppc__

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/SmallBitVector.h"
#include "gtest/gtest.h"

using namespace llvm;

namespace {

// Test fixture
template <typename T>
class BitVectorTest : public ::testing::Test { };

// Test both BitVector and SmallBitVector with the same suite of tests.
typedef ::testing::Types<BitVector, SmallBitVector> BitVectorTestTypes;
TYPED_TEST_CASE(BitVectorTest, BitVectorTestTypes);

TYPED_TEST(BitVectorTest, TrivialOperation) {
  TypeParam Vec;
  EXPECT_EQ(0U, Vec.count());
  EXPECT_EQ(0U, Vec.size());
  EXPECT_FALSE(Vec.any());
  EXPECT_TRUE(Vec.all());
  EXPECT_TRUE(Vec.none());
  EXPECT_TRUE(Vec.empty());

  Vec.resize(5, true);
  EXPECT_EQ(5U, Vec.count());
  EXPECT_EQ(5U, Vec.size());
  EXPECT_TRUE(Vec.any());
  EXPECT_TRUE(Vec.all());
  EXPECT_FALSE(Vec.none());
  EXPECT_FALSE(Vec.empty());

  Vec.resize(11);
  EXPECT_EQ(5U, Vec.count());
  EXPECT_EQ(11U, Vec.size());
  EXPECT_TRUE(Vec.any());
  EXPECT_FALSE(Vec.all());
  EXPECT_FALSE(Vec.none());
  EXPECT_FALSE(Vec.empty());

  TypeParam Inv = Vec;
  Inv.flip();
  EXPECT_EQ(6U, Inv.count());
  EXPECT_EQ(11U, Inv.size());
  EXPECT_TRUE(Inv.any());
  EXPECT_FALSE(Inv.all());
  EXPECT_FALSE(Inv.none());
  EXPECT_FALSE(Inv.empty());

  EXPECT_FALSE(Inv == Vec);
  EXPECT_TRUE(Inv != Vec);
  Vec.flip();
  EXPECT_TRUE(Inv == Vec);
  EXPECT_FALSE(Inv != Vec);

  // Add some "interesting" data to Vec.
  Vec.resize(23, true);
  Vec.resize(25, false);
  Vec.resize(26, true);
  Vec.resize(29, false);
  Vec.resize(33, true);
  Vec.resize(57, false);
  unsigned Count = 0;
  for (unsigned i = Vec.find_first(); i != -1u; i = Vec.find_next(i)) {
    ++Count;
    EXPECT_TRUE(Vec[i]);
    EXPECT_TRUE(Vec.test(i));
  }
  EXPECT_EQ(Count, Vec.count());
  EXPECT_EQ(Count, 23u);
  EXPECT_FALSE(Vec[0]);
  EXPECT_TRUE(Vec[32]);
  EXPECT_FALSE(Vec[56]);
  Vec.resize(61, false);

  TypeParam Copy = Vec;
  TypeParam Alt(3, false);
  Alt.resize(6, true);
  std::swap(Alt, Vec);
  EXPECT_TRUE(Copy == Alt);
  EXPECT_TRUE(Vec.size() == 6);
  EXPECT_TRUE(Vec.count() == 3);
  EXPECT_TRUE(Vec.find_first() == 3);
  std::swap(Copy, Vec);

  // Add some more "interesting" data.
  Vec.resize(68, true);
  Vec.resize(78, false);
  Vec.resize(89, true);
  Vec.resize(90, false);
  Vec.resize(91, true);
  Vec.resize(130, false);
  Count = 0;
  for (unsigned i = Vec.find_first(); i != -1u; i = Vec.find_next(i)) {
    ++Count;
    EXPECT_TRUE(Vec[i]);
    EXPECT_TRUE(Vec.test(i));
  }
  EXPECT_EQ(Count, Vec.count());
  EXPECT_EQ(Count, 42u);
  EXPECT_FALSE(Vec[0]);
  EXPECT_TRUE(Vec[32]);
  EXPECT_FALSE(Vec[60]);
  EXPECT_FALSE(Vec[129]);

  Vec.flip(60);
  EXPECT_TRUE(Vec[60]);
  EXPECT_EQ(Count + 1, Vec.count());
  Vec.flip(60);
  EXPECT_FALSE(Vec[60]);
  EXPECT_EQ(Count, Vec.count());

  Vec.reset(32);
  EXPECT_FALSE(Vec[32]);
  EXPECT_EQ(Count - 1, Vec.count());
  Vec.set(32);
  EXPECT_TRUE(Vec[32]);
  EXPECT_EQ(Count, Vec.count());

  Vec.flip();
  EXPECT_EQ(Vec.size() - Count, Vec.count());

  Vec.reset();
  EXPECT_EQ(0U, Vec.count());
  EXPECT_EQ(130U, Vec.size());
  EXPECT_FALSE(Vec.any());
  EXPECT_FALSE(Vec.all());
  EXPECT_TRUE(Vec.none());
  EXPECT_FALSE(Vec.empty());

  Inv = TypeParam().flip();
  EXPECT_EQ(0U, Inv.count());
  EXPECT_EQ(0U, Inv.size());
  EXPECT_FALSE(Inv.any());
  EXPECT_TRUE(Inv.all());
  EXPECT_TRUE(Inv.none());
  EXPECT_TRUE(Inv.empty());

  Vec.clear();
  EXPECT_EQ(0U, Vec.count());
  EXPECT_EQ(0U, Vec.size());
  EXPECT_FALSE(Vec.any());
  EXPECT_TRUE(Vec.all());
  EXPECT_TRUE(Vec.none());
  EXPECT_TRUE(Vec.empty());
}

TYPED_TEST(BitVectorTest, CompoundAssignment) {
  TypeParam A;
  A.resize(10);
  A.set(4);
  A.set(7);

  TypeParam B;
  B.resize(50);
  B.set(5);
  B.set(18);

  A |= B;
  EXPECT_TRUE(A.test(4));
  EXPECT_TRUE(A.test(5));
  EXPECT_TRUE(A.test(7));
  EXPECT_TRUE(A.test(18));
  EXPECT_EQ(4U, A.count());
  EXPECT_EQ(50U, A.size());

  B.resize(10);
  B.set();
  B.reset(2);
  B.reset(7);
  A &= B;
  EXPECT_FALSE(A.test(2));
  EXPECT_FALSE(A.test(7));
  EXPECT_EQ(2U, A.count());
  EXPECT_EQ(50U, A.size());

  B.resize(100);
  B.set();

  A ^= B;
  EXPECT_TRUE(A.test(2));
  EXPECT_TRUE(A.test(7));
  EXPECT_EQ(98U, A.count());
  EXPECT_EQ(100U, A.size());
}

TYPED_TEST(BitVectorTest, ProxyIndex) {
  TypeParam Vec(3);
  EXPECT_TRUE(Vec.none());
  Vec[0] = Vec[1] = Vec[2] = true;
  EXPECT_EQ(Vec.size(), Vec.count());
  Vec[2] = Vec[1] = Vec[0] = false;
  EXPECT_TRUE(Vec.none());
}

TYPED_TEST(BitVectorTest, PortableBitMask) {
  TypeParam A;
  const uint32_t Mask1[] = { 0x80000000, 6, 5 };

  A.resize(10);
  A.setBitsInMask(Mask1, 3);
  EXPECT_EQ(10u, A.size());
  EXPECT_FALSE(A.test(0));

  A.resize(32);
  A.setBitsInMask(Mask1, 3);
  EXPECT_FALSE(A.test(0));
  EXPECT_TRUE(A.test(31));
  EXPECT_EQ(1u, A.count());

  A.resize(33);
  A.setBitsInMask(Mask1, 1);
  EXPECT_EQ(1u, A.count());
  A.setBitsInMask(Mask1, 2);
  EXPECT_EQ(1u, A.count());

  A.resize(34);
  A.setBitsInMask(Mask1, 2);
  EXPECT_EQ(2u, A.count());

  A.resize(65);
  A.setBitsInMask(Mask1, 3);
  EXPECT_EQ(4u, A.count());

  A.setBitsNotInMask(Mask1, 1);
  EXPECT_EQ(32u+3u, A.count());

  A.setBitsNotInMask(Mask1, 3);
  EXPECT_EQ(65u, A.count());

  A.resize(96);
  EXPECT_EQ(65u, A.count());

  A.clear();
  A.resize(128);
  A.setBitsNotInMask(Mask1, 3);
  EXPECT_EQ(96u-5u, A.count());

  A.clearBitsNotInMask(Mask1, 1);
  EXPECT_EQ(64-4u, A.count());
}

TYPED_TEST(BitVectorTest, BinOps) {
  TypeParam A;
  TypeParam B;

  A.resize(65);
  EXPECT_FALSE(A.anyCommon(B));
  EXPECT_FALSE(B.anyCommon(B));

  B.resize(64);
  A.set(64);
  EXPECT_FALSE(A.anyCommon(B));
  EXPECT_FALSE(B.anyCommon(A));

  B.set(63);
  EXPECT_FALSE(A.anyCommon(B));
  EXPECT_FALSE(B.anyCommon(A));

  A.set(63);
  EXPECT_TRUE(A.anyCommon(B));
  EXPECT_TRUE(B.anyCommon(A));

  B.resize(70);
  B.set(64);
  B.reset(63);
  A.resize(64);
  EXPECT_FALSE(A.anyCommon(B));
  EXPECT_FALSE(B.anyCommon(A));
}
}
#endif

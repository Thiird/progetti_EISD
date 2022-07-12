#ifndef __define_UT_h__
#define __define_UT_h__

#include <systemc.h>


struct iostruct {
  sc_uint<32> datain;
  sc_uint<32> result;
};

struct m_iostruct {
  sc_uint<64> datain1;
  sc_uint<64> datain2;
  sc_uint<32> result[4];
};


inline sc_uint<16> extract(int i, sc_uint<64> mat)
{
  unsigned int shift = i * 16;
  return (mat & (0xffffull << shift)) >> shift;
}

#define ADDRESS_TYPE int
#define DATA_TYPE iostruct

#endif

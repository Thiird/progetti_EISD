#ifndef _div_UT_TESTBENCH_H_
#define _div_UT_TESTBENCH_H_

#include <systemc.h>
#include <tlm.h>
#include "define_UT.hh"

class mmul_UT_testbench
  : public sc_module
  , public virtual tlm::tlm_bw_transport_if<>
{

private:

  SC_HAS_PROCESS(mmul_UT_testbench);

  virtual void invalidate_direct_mem_ptr(uint64 start_range, uint64 end_range);

  virtual tlm::tlm_sync_enum nb_transport_bw(tlm::tlm_generic_payload &  trans, tlm::tlm_phase &  phase, sc_time &  t);

  void run();

public:

  tlm::tlm_initiator_socket<> initiator_socket;

  mmul_UT_testbench(sc_module_name name);

  void printres(sc_uint<32>result []);
  void print(sc_uint<64> data);
};

#endif

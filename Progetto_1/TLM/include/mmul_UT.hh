#ifndef __mmul_UT_HPP__
#define __mmul_UT_HPP__

#include <systemc.h>
#include <tlm.h>
#include "define_UT.hh"

class mmul_UT
  : public sc_module
  , public virtual tlm::tlm_fw_transport_if<>
  , public virtual tlm::tlm_bw_transport_if<>
{
  private:

  virtual void invalidate_direct_mem_ptr(uint64 start_range, uint64 end_range);

   virtual tlm::tlm_sync_enum nb_transport_bw(tlm::tlm_generic_payload &  trans, tlm::tlm_phase &  phase, sc_time &  t);


 public:

  tlm::tlm_target_socket<> target_socket;
  tlm::tlm_initiator_socket<> initiator_socket;


  virtual void b_transport(tlm::tlm_generic_payload& trans, sc_time& t);

  virtual bool get_direct_mem_ptr(tlm::tlm_generic_payload& trans, tlm::tlm_dmi& dmi_data);

  virtual tlm::tlm_sync_enum nb_transport_fw(tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t);

  virtual unsigned int transport_dbg(tlm::tlm_generic_payload& trans);

  m_iostruct  m_ioDataStruct;
  tlm::tlm_generic_payload* pending_transaction;
  sc_int<32> tmp_result[4];

  void mmul_function();


  void end_of_elaboration();

  void reset();

  SC_HAS_PROCESS(mmul_UT);

  mmul_UT(sc_module_name name_);

};

#endif

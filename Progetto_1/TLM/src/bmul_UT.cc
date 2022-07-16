#include "bmul_UT.hh"
#include <bitset>

bmul_UT::bmul_UT(sc_module_name name_)
  : sc_module(name_)
  , target_socket("target_socket")
  , pending_transaction(NULL)
{
  target_socket(*this);
}

void bmul_UT::b_transport(tlm::tlm_generic_payload& trans, sc_time& t)
{
  ioDataStruct = *((iostruct*) trans.get_data_ptr());

  if (trans.is_write()) {
    bmul_function();
    trans.set_response_status(tlm::TLM_OK_RESPONSE);
    *((iostruct*) trans.get_data_ptr()) = ioDataStruct;
  }
  else if (trans.is_read()){
    ioDataStruct.result = tmp_result;
    *((iostruct*) trans.get_data_ptr()) = ioDataStruct;
  }
}

bool bmul_UT::get_direct_mem_ptr(tlm::tlm_generic_payload& trans, tlm::tlm_dmi& dmi_data)
{
  return false;
}

tlm::tlm_sync_enum bmul_UT::nb_transport_fw(tlm::tlm_generic_payload& trans, tlm::tlm_phase & phase, sc_time & t)
{
  return tlm::TLM_COMPLETED;
}

unsigned int bmul_UT::transport_dbg(tlm::tlm_generic_payload& trans)
{
  return 0;
}

void bmul_UT:: bmul_function()
{
  //This function have some problems
  unsigned int M1 = 0;
  unsigned int M2 = 0;
  unsigned int bmul =0;

  unsigned int tmp;
  tmp = ioDataStruct.datain;

  //dispach of data
  M1 = (tmp & 0xffff0000u) >> 16;
  M2 = (tmp & 0x0000ffffu);

  //evaluate
  bmul = M1 * M2;

  //build result
  tmp_result = bmul;
}

// Initialization:
void bmul_UT:: end_of_elaboration(){
}

void bmul_UT:: reset(){
}

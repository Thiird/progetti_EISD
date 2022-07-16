#include "mmul_UT.hh"
#include <bitset>

mmul_UT::mmul_UT(sc_module_name name_)
  : sc_module(name_)
  , target_socket("target_socket")
  , initiator_socket("init")
  , pending_transaction(NULL)
{
  target_socket(*this);
  initiator_socket(*this);
}

void mmul_UT::invalidate_direct_mem_ptr(uint64 start_range, uint64 end_range){
}

tlm::tlm_sync_enum mmul_UT::nb_transport_bw(tlm::tlm_generic_payload &  trans, tlm::tlm_phase &  phase, sc_time &  t){
  return tlm::TLM_COMPLETED;
}

void mmul_UT::b_transport(tlm::tlm_generic_payload& trans, sc_time& t){
  m_ioDataStruct = *((m_iostruct*) trans.get_data_ptr());

  if (trans.is_write()) {
    mmul_function();
    trans.set_response_status(tlm::TLM_OK_RESPONSE);
    *((m_iostruct*) trans.get_data_ptr()) = m_ioDataStruct;
  }
  else if (trans.is_read()){
    memcpy(m_ioDataStruct.result, tmp_result, sizeof(sc_uint<32>) * 4);
    *((m_iostruct*) trans.get_data_ptr()) = m_ioDataStruct;
  }

}

bool mmul_UT::get_direct_mem_ptr(tlm::tlm_generic_payload& trans, tlm::tlm_dmi& dmi_data){
  return false;
}

tlm::tlm_sync_enum mmul_UT::nb_transport_fw(tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t){
  return tlm::TLM_COMPLETED;
}

unsigned int mmul_UT::transport_dbg(tlm::tlm_generic_payload& trans){
  return 0;
}

void mmul_UT:: mmul_function()
{
  //Multiply matrices by calling bmul module and store results
  //RES[0][0]= A[0][0]*B[0][0] + A[0][1]*B[1][0] ...

  //variables to communicate with bmul
  iostruct bmul_packet;
  tlm::tlm_generic_payload payload;
  sc_uint<32> tmp1,tmp2;
  sc_time local_time;

  //Multiply every row for every column
  for(int i = 0; i < 2; i ++){
    for(int j=0; j <2; j++){
      //First two numbers to multiply
      bmul_packet.datain  = extract(j * 2 + 0, m_ioDataStruct.datain1) << 16;
      bmul_packet.datain += extract(0 * 2 + i, m_ioDataStruct.datain1);

      payload.set_data_ptr((unsigned char*) &bmul_packet);
      payload.set_address(0);
      payload.set_write();

      // start write transaction
      initiator_socket->b_transport(payload, local_time);

      // start read transaction
      payload.set_read();

      initiator_socket->b_transport(payload, local_time);
      if(payload.get_response_status() == tlm::TLM_OK_RESPONSE){
        tmp1 = bmul_packet.result;
      }

      //Second two to multiply
      bmul_packet.datain  = extract(j * 2 + 1,m_ioDataStruct.datain1) << 16;
      bmul_packet.datain += extract(1 * 2 + i,m_ioDataStruct.datain1);

      payload.set_data_ptr((unsigned char*) &bmul_packet);
      payload.set_address(0);
      payload.set_write();

      // start write transaction
      initiator_socket->b_transport(payload, local_time);

      // start read transaction
      payload.set_read();

      initiator_socket->b_transport(payload, local_time);
      if(payload.get_response_status() == tlm::TLM_OK_RESPONSE){
        tmp2 = bmul_packet.result;
      }

      //Sum the two multiplication results to make a cell of the result matrix
      tmp_result[i*2+j] = (tmp1 + tmp2);
    }
  }
}

// Initialization:
void mmul_UT:: end_of_elaboration(){
}

void mmul_UT:: reset(){
}

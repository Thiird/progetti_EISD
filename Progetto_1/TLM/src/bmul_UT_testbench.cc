#include "bmul_UT_testbench.hh"

#include <bitset>

void bmul_UT_testbench::invalidate_direct_mem_ptr(uint64 start_range, uint64 end_range)
{
  
}

tlm::tlm_sync_enum bmul_UT_testbench::nb_transport_bw(tlm::tlm_generic_payload &  trans, tlm::tlm_phase &  phase, sc_time &  t)
{
  return tlm::TLM_COMPLETED;
}


void bmul_UT_testbench::run()
{

  sc_time local_time;
  // First transaction (initialization)
  iostruct bmul_packet;
  tlm::tlm_generic_payload payload;	

  cout<<"Calculate the bmul function for 2 numbers of 16 bits!"<<endl;

  
    bmul_packet.datain = (rand() % 256) << 24; 
    bmul_packet.datain += (rand() % 256) << 16;  
    bmul_packet.datain += (rand() % 256) << 8;
    bmul_packet.datain += (rand() % 256);

    cout << "\tmult:\t" 
         << std::bitset<32>(bmul_packet.datain) 
         << endl;
    
    payload.set_data_ptr((unsigned char*) &bmul_packet);
    payload.set_address(0);
    payload.set_write();

    // start write transaction
    initiator_socket->b_transport(payload, local_time);


    // start read transaction
    payload.set_read();

    initiator_socket->b_transport(payload, local_time);
    if(payload.get_response_status() == tlm::TLM_OK_RESPONSE){
      cout << "\tresult:\t" 
           << std::bitset<32>(bmul_packet.result) 
           << endl;
    }

  
  sc_stop();
  
}





bmul_UT_testbench::bmul_UT_testbench(sc_module_name name)
  : sc_module(name)
{

  initiator_socket(*this);

  SC_THREAD(run);

}

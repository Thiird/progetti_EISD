#include "mmul_UT_testbench.hh"

#include <bitset>

tlm::tlm_sync_enum mmul_UT_testbench::nb_transport_bw(tlm::tlm_generic_payload &  trans, tlm::tlm_phase &  phase, sc_time &  t)
{
  return tlm::TLM_COMPLETED;
}

void mmul_UT_testbench::invalidate_direct_mem_ptr(uint64 start_range, uint64 end_range)
{
  
}

void mmul_UT_testbench::run()
{
  clock_t begin = clock();
  sc_time local_time;
  // First transaction (initialization)
  m_iostruct mmul_packet;
  tlm::tlm_generic_payload payload;	

  cout<<"Calculate the mmul function!"<<endl;

    mmul_packet.datain1  = 0b0000000000000001ull;//(rand() % 65000); 
    mmul_packet.datain1 += 0b0000000000000000ull << 16; //(rand() % 65000) << 16;
    mmul_packet.datain1 += 0b0000000000000000ull << 32; //(rand() % 256)   << 32;
    mmul_packet.datain1 += 0b0000000000000001ull << 48; //(rand() % 65000) << 48;

    mmul_packet.datain2  = 0b0000000000000001ull; //(rand() % 65000); 
    mmul_packet.datain2 += 0b0000000000000000ull << 16;//(rand() % 65000) << 16;
    mmul_packet.datain2 += 0b0000000000000000ull << 32;//((rand() % 256)) << 32;
    mmul_packet.datain2 += 0b0000000000000001ull << 48;//(rand() % 65000) << 48;

    //cout << std::bitset<64>((unsigned long int) mmul_packet.datain1) << "\n";
    cout << "\tPrinting matrices:\t";
    cout<<"A: " <<endl; 
    print(mmul_packet.datain1);      
    cout<<"B: " <<endl; 
    print(mmul_packet.datain2);    
    cout<< endl;
    
    payload.set_data_ptr((unsigned char*) &mmul_packet);
    payload.set_address(0);
    payload.set_write();

    // start write transaction
    initiator_socket->b_transport(payload, local_time);


    // start read transaction
    payload.set_read();

    initiator_socket->b_transport(payload, local_time);
    if(payload.get_response_status() == tlm::TLM_OK_RESPONSE){
      cout << "\tresult:\t\n" ;
        
      printres(mmul_packet.result);
      
      cout<<endl;
    }

  clock_t end = clock();
  double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
  cout<< "Simulation time:" <<time_spent <<" sec \n" ; 
  sc_stop();
  
}

void mmul_UT_testbench::printres( sc_uint<32> result [])
{
    for(int i = 0; i< 4 ; i++){
        cout<<i*16 <<"bits: "  << std::bitset<32>(result[i]) << "\n";
    }
}

void mmul_UT_testbench::print(sc_uint<64> datain){
  cout<<endl;
  for(int i = 0; i < 4; i++){
  
      cout<<i*16 <<"bits: "  << std::bitset<32>((unsigned int)extract( i, datain)) << "\n"; 
  
    }
    cout <<endl;
}



mmul_UT_testbench::mmul_UT_testbench(sc_module_name name)
  : sc_module(name)
{

  initiator_socket(*this);

  SC_THREAD(run);

}

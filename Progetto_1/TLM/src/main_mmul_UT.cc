#include "mmul_UT.hh"
#include "bmul_UT.hh"
#include "mmul_UT_testbench.hh"

class mmul_top : public sc_module
{

private:

  mmul_UT  m_matrix_mul;

  bmul_UT m_binary_mul;

  mmul_UT_testbench m_initiator;


public:

  mmul_top(sc_module_name name)
    : sc_module(name)
    , m_initiator("initiator") 
    , m_matrix_mul("mmul")
    , m_binary_mul("binary_mul")
  {
    m_initiator.initiator_socket(m_matrix_mul.target_socket);
    m_matrix_mul.initiator_socket(m_binary_mul.target_socket);
  }

};

int main(int argc, char* argv[])
{

  mmul_top top("top");
  
  sc_start();

  return 0;

}

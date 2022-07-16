#include "bmul_UT.hh"
#include "bmul_UT_testbench.hh"

class bmul_top : public sc_module
{
  private:
    bmul_UT  m_target;
    bmul_UT_testbench m_initiator;

  public:
    bmul_top(sc_module_name name)
      : sc_module(name)
      , m_target("target")
      , m_initiator("initiator")
    {
      m_initiator.initiator_socket(m_target.target_socket);
    }
};

int main(int argc, char* argv[])
{
  bmul_top top("top");
  sc_start();

  return 0;
}

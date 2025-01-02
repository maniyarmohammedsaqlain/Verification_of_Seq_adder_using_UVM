module tb();
  add_if aif();
  initial
    begin
      aif.clk=0;
      aif.rst=0;
    end
  always
    #10 aif.clk=~aif.clk;
  add adddut(.clk(aif.clk),.rst(aif.rst),.a(aif.a),.b(aif.b),.y(aif.y));
  initial
    begin
      uvm_config_db #(virtual add_if)::set(null,"*","aif",aif);
      run_test("test");
    end
endmodule

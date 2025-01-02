class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  transaction trans;
  uvm_analysis_imp #(transaction,scoreboard) recv;
  function new(string path="scb",uvm_component parent=null);
    super.new(path,parent);
    recv=new("recv",this);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
  endfunction
  virtual function void write(transaction tra);
    trans=tra;
    `uvm_info("SCB",$sformatf("Data recieved here is a :%0d b: %0d y:%0d",trans.a,trans.b,trans.y),UVM_NONE);
    if(trans.a+trans.b==trans.y)
      begin
        `uvm_info("SCB","PASSED",UVM_NONE);
      end
    else
      begin
        `uvm_info("SCB","FAILED",UVM_NONE);
      end
  endfunction
endclass

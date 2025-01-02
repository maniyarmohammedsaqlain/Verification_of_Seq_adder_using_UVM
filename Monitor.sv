class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  transaction trans;
  uvm_analysis_port #(transaction) send;
  virtual add_if aif;
  function new(string path="mon",uvm_component parent=null);
    super.new(path,parent);
    send=new("send",this);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
    if(!uvm_config_db #(virtual add_if)::get(this,"","aif",aif))
      `uvm_info("monconfig","ERROR IN CONFIG MON",UVM_NONE);
  endfunction
  virtual task run_phase(uvm_phase phase);
    @(negedge aif.rst)
    forever
      begin
        repeat(2) @(posedge aif.clk);
        trans.a=aif.a;
        trans.b=aif.b;
        trans.y=aif.y;
        `uvm_info("MON",$sformatf("a :%0d b: %0d y:%0d",trans.a,trans.b,trans.y),UVM_NONE);
        send.write(trans);
      end
  endtask
endclass

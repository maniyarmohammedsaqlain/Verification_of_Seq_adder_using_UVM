class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver);
  transaction trans;
  virtual add_if aif;
  function new(string path="drv",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
    if(!uvm_config_db #(virtual add_if)::get(this,"","aif",aif))
      `uvm_info("drvconfig","ERROR IN CONFIG DRV",UVM_NONE);
  endfunction
  task reset();
    aif.a<=0;
    aif.b<=0;
    aif.rst<=1'b1;
    repeat(3) @(posedge aif.clk);
    aif.rst<=0;
    `uvm_info("DRVRST","RESET DONE",UVM_NONE);
  endtask
  virtual task run_phase(uvm_phase phase);
    reset();
    forever
      begin
        seq_item_port.get_next_item(trans);
        aif.a<=trans.a;
        aif.b<=trans.b;
        `uvm_info("DRV",$sformatf("Data recieved of a:%0d b:%0d",trans.a,trans.b),UVM_NONE);
        seq_item_port.item_done();
        @(posedge aif.clk);
        @(posedge aif.clk);
      end
  endtask
endclass

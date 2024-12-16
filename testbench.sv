`include "uvm_macros.svh";
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  rand bit [3:0]a;
  rand bit [3:0]b;
  bit [4:0]y;
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(a,UVM_DEFAULT);
  `uvm_field_int(b,UVM_DEFAULT);
  `uvm_field_int(y,UVM_DEFAULT);
  `uvm_object_utils_end
  function new(string path="trans");
    super.new(path);
  endfunction
endclass

class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1);
  transaction trans;
  function new(string path="sequence1");
    super.new(path);
  endfunction
  virtual task body();
    repeat(10)
      begin
        trans=transaction::type_id::create("trans");
        start_item(trans);
        trans.randomize();
        finish_item(trans);
      end
  endtask
endclass

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

class agent extends uvm_agent;
  `uvm_component_utils(agent);
  monitor mon;
  driver drv;
  uvm_sequencer #(transaction)seqr;
  function new(string path="agent",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv=driver::type_id::create("drv",this);
    mon=monitor::type_id::create("mon",this);
    seqr=uvm_sequencer #(transaction)::type_id::create("seqr",this);
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env);
  agent a;
  scoreboard scb;
  function new(string path="scb",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a=agent::type_id::create("a",this);
    scb=scoreboard::type_id::create("scb",this);
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.mon.send.connect(scb.recv);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test);
  env e;
  sequence1 seq;
  function new(string path="test",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e=env::type_id::create("e",this);
    seq=sequence1::type_id::create("seq",this);
  endfunction
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(e.a.seqr);
    #50;
    phase.drop_objection(this);
  endtask
endclass
  
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

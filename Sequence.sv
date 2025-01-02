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

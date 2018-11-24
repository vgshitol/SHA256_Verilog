#------------------------------------------------------------
#
# Basic Synthesis Script (TCL format)
#                                  
# Revision History                
#   1/15/03  : Author Shane T. Gehring - from class example
#   2/09/07  : Author Zhengtao Yu      - from class example
#   12/14/07 : Author Ravi Jenkal      - updated to 180 nm & tcl
#
#------------------------------------------------------------

#---------------------------------------------------------
# Read in Verilog file and map (synthesize) onto a generic
# library.
# MAKE SURE THAT YOU CORRECT ALL WARNINGS THAT APPEAR
# during the execution of the read command are fixed 
# or understood to have no impact.
# ALSO CHECK your latch/flip-flop list for unintended 
# latches                                            
#---------------------------------------------------------

read_verilog $RTL_DIR/msgEn.v
read_verilog $RTL_DIR/wEn.v
read_verilog $RTL_DIR/counter.v
read_verilog $RTL_DIR/counter_h.v
read_verilog $RTL_DIR/msg_vector.v
read_verilog $RTL_DIR/hash.v
read_verilog $RTL_DIR/counter_wk.v
read_verilog $RTL_DIR/k_vector.v
read_verilog $RTL_DIR/w64.v
read_verilog $RTL_DIR/hash_update.v
read_verilog $RTL_DIR/store_hash.v
read_verilog $RTL_DIR/${modname}.v



create_clock -name vclk -period 500
set_input_delay 0.2 -clock vclk [all_inputs]
set_output_delay 0.001 -clock vclk [all_outputs]
set_input_transition 0.2 [all_inputs]
set_max_capacitance 30 [get_ports]
set_load 0.15 [all_outputs]

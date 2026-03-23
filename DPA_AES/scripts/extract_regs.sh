#!/bin/bash

# Extracts all register names from VCD File into a CSV file (registers.csv).
# CSV file has 5 columns. Because UID can contain a comma, the delimter for CSV is now a SPACE.
# Num Bits, Reg UID in VCD, Reg Name, MSB (Num Bits - 1), LSB (generally 0)

input_file=$1  # Input VCD file
output_reg_file=$2 # Output file with regs

> $output_reg_file
> $output_vcd_file

awk '/\$var reg/,/\$end/' $input_file > $output_reg_file
sed -i 's/.*\(reg\) \([^ ]*\) \([^ ]*\) \([^ ]*\) \[\([^:]*\):\([^:]*\)\].*$end.*/\4/' $output_reg_file
sed -i 's/.*\(reg\) \([^ ]*\) \([^ ]*\) \([^ ]*\) .*$end.*/\4/' $output_reg_file



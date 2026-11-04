

# Hardware Trojan Documentation: Bit-Check Omission in Password Verification

## Overview

This repository documents a logic-based hardware Trojan implemented within a JTAG TAP (Test Access Port) controller. The Trojan exploits an off-by-one bug in password verification logic, bypassing secure access by checking only 31 out of 32 bits of a required password. This subtle manipulation introduces a hidden vulnerability that can be exploited to gain unauthorized access.

## Location

The Trojan resides in the `adbg_tap_top.sv` module, specifically within the `run_test_idle` state of the TAP controller's finite state machine.

## Behavior

In the affected code block:

```verilog
if (correct >= 32'h0000001F) begin
    passchk = 1;
end else if (tdi_o == pass[bitindex]) begin
    correct = correct + 1;
    bitindex = bitindex + 1;
end
```

The condition checks whether **31 bits** have been matched correctly (`0x1F`), instead of the full **32 bits**. This omission effectively allows any bit value in the least significant bit (LSB) position, enabling attackers to bypass full password verification with a reduced brute-force effort.

## Security Implications

- **Backdoor Access**: An attacker only needs to guess 31 bits correctly; the 32nd bit can be arbitrary.
- **Reduced Entropy**: Brute-force complexity is halved (2³¹ vs. 2³² attempts).
- **Hard to Detect**: The logic appears functionally correct and may evade traditional testing and simulation methods.
- **Rare Trigger Conditions**: Makes detection difficult during standard validation flows.

## Classification

| Attribute       | Value                              |
|----------------|-------------------------------------|
| Type           | Logic-based Hardware Trojan         |
| Trigger        | 31 correct bits of a 32-bit password|
| Payload        | Sets `passchk = 1`                  |
| Activation     | Only when input matches 31 bits     |
| Stealth Level  | High (appears as off-by-one error)  |

## Detection Methods

### 1. Formal Verification
Use SystemVerilog Assertions (SVA) to assert full-bit equivalence:

```systemverilog
property full_bit_check;
    @(posedge tck_pad_i) (correct == 32'h00000020) |-> $rose(passchk);
endproperty

assert property (full_bit_check) else $error("Full 32-bit match not enforced.");
```

### 2. Linting and Static Analysis
Run linting tools to detect improper constants or hardcoded values. Flag constants like `0x1F` in bit comparison logic where `0x20` is expected.


## Mitigation

To correct the vulnerability, update the comparison constant:

```verilog
// Original
if (correct >= 32'h0000001F)

// Fixed
if (correct >= 32'h00000020)
```

Ensure this logic is enforced in both simulation and synthesis paths.

## Summary

This example demonstrates how a single-bit logic omission can introduce a stealthy and high-impact hardware Trojan. Detection requires a combination of formal verification, rigorous code review, and security-aware design practices. It highlights the critical importance of ensuring complete bit-wise verification in secure hardware design.
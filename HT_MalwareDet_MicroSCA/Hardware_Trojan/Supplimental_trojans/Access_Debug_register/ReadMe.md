# Hardware Trojan Documentation: Unauthorized Debug Register Access in Halt Mode

## Overview
This document describes a security vulnerability found in the `riscv_debug_unit.sv` module. The issue constitutes a potential hardware Trojan that allows unauthorized access to internal debug registers when the processor is **not in halt mode**, violating standard debug access restrictions.

## Location
**File:** `riscv_debug_unit.sv`  
**Functionality Block:** CSR (Control and Status Register) access logic  
**Condition Trigger:** `debug_addr_i[14] == 1` (CSR access request)

The vulnerability is present in the state machine handling debug register access, specifically in the transition to the `SECOND` state, where access is granted unconditionally without checking whether the core is in `halt` mode.

## Behavior
The debug interface processes register access requests in a two-stage pipeline controlled by a state machine (`state_q`, `state_n`). In the `FIRST` state, access is gated with a check on `debug_halted_o`. However, in the `SECOND` state, the logic grants write access (`csr_we_o = 1'b1`) without validating the halt condition.

As a result, an attacker with access to the debug interface can perform unauthorized CSR writes even when the processor is not halted.

## Security Implication
This logic flaw undermines core system protections by:
- Allowing unauthorized modification of debug CSRs during normal processor operation.
- Enabling potential leakage of privileged state or memory content.
- Bypassing expected debug-mode isolation, potentially leading to privilege escalation or denial-of-service attacks.

Such access can be used to subvert secure boot processes, manipulate instruction flow, or leak cryptographic keys and private data.

## Classification
This vulnerability can be classified as a **hardware Trojan**, exhibiting the following traits:
- **Stealth**: The trigger is hidden within a common operational path (debug access).
- **Selective activation**: Exploits timing and state transitions (e.g., `SECOND` state) to bypass checks.
- **Payload**: Enables write access to restricted debug registers in violation of design policy.
- **Low area footprint**: The logic appears benign unless carefully reviewed.

### Type:
- **Trigger**: Implicit (state machine logic)
- **Payload**: Unauthorized debug register access
- **Insertion phase**: RTL

## Detection Methods
The following approaches can be used to detect this vulnerability:

1. **Code Review**:
   - Manual inspection of access control logic in debug interfaces.
   - Verification of conditional checks for `debug_halted_o` before granting access.

2. **Formal Verification**:
   - Use of assertions to ensure debug register writes can only occur when the core is halted.
   - Property: 
   
```systemverilog
property debug_halt_check;
  @(posedge clk) (debug_req_i && (debug_addr_i[13:8] == 6'b10_0000)) |-> debug_halted_o;
endproperty

assert property (debug_halt_check)
else $error("Unauthorized access to debug registers without the core being in debug halt mode.");
```

3. **Simulation**:
   - Stimuli that attempt to write to debug registers while the processor is running.
   - Check for unexpected grant signals (`debug_gnt_o`) or write enables (`csr_we_o`).

## Mitigation
To mitigate this Trojan, the CSR write logic must be gated by an explicit check on the processor's halted state in **all pipeline stages**. The following fix is recommended:

### Original vulnerable logic:
```systemverilog
else begin
  debug_gnt_o = 1'b1;
  state_n     = FIRST;
  csr_we_o    = 1'b1;
end
```

### Fixed logic:
```systemverilog
else begin
  if (debug_halted_o) begin
    debug_gnt_o = 1'b1;
    csr_we_o    = 1'b1;
  end else begin
    debug_gnt_o = 1'b0;
    csr_we_o    = 1'b0;
  end
  state_n = FIRST;
end
```

Additionally:
- Add RTL assertions to enforce this condition.
- Conduct a full audit of debug and test access points.
- Implement signal hardening and privilege level checks around debug interfaces.

## Summary
The discovered Trojan exploits a flaw in the debug unit's state machine to allow unauthorized access to debug registers while the processor is running. Its stealth, low footprint, and potentially severe consequences mark it as a serious threat. Mitigating this vulnerability requires code correction, formal validation, and ongoing verification to ensure secure debug access behavior.
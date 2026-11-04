
# Hardware Trojan Documentation: GPIO Lock Register Vulnerability

## Overview

A security-critical vulnerability has been identified in the GPIO peripheral module. The issue enables software to directly overwrite the GPIO lock control register, which is intended to restrict modifications to GPIO configuration registers once locked. This behavior deviates from the expected hardware locking mechanism and can lead to a potential security breach. The vulnerability may constitute a hardware Trojan if introduced with malicious intent.

## Location

**File**: `apb_gpio.sv`  
**Register**: `r_gpio_lock`  
**Address**: `BASEADDR + 0x48`  
**Definition**:  
```systemverilog
`define REG_GPIOLOCK    5'b10010
logic [31:0] r_gpio_lock;
...
`REG_GPIOLOCK:
    r_gpio_lock <= PWDATA;
```

## Behaviour

The `r_gpio_lock` register is used to lock access to critical GPIO configuration registers. However, it is currently implemented such that it can be completely overwritten by software writes via the APB interface. This allows the lock bits to be cleared, effectively disabling the intended protection mechanism.

Expected behavior:  
- Lock bits should only be set (`0` to `1`) and remain set until reset.
- Lock bits should not be cleared by software.

Observed behavior:  
- `PWDATA` directly replaces the value of `r_gpio_lock`.
- Software can clear previously set lock bits.

## Security Implication

This behavior introduces a critical vulnerability with the following implications:
- Unauthorized software can unlock GPIO registers and alter their configuration.
- It may enable privilege escalation, hardware control manipulation, or data leakage via GPIO pins.
- In systems where GPIOs are used for secure boot, sensor integrity, or fail-safe logic, this can result in complete system compromise.
- If introduced intentionally, this mechanism serves as a stealthy hardware Trojan that bypasses established protections.

## Classification

- **Type**: Hardware Trojan
- **Class**: Functional (modifies control flow or security functionality)
- **Trigger**: Software write to `REG_GPIOLOCK` address
- **Payload**: Disables lock mechanism protecting GPIO configuration
- **Stealth**: High (blends with standard register write logic)

## Detection Methods

- **Code Review**: Manual inspection of the register write logic for unexpected write permissions.
- **Formal Verification**: Use of SystemVerilog assertions to detect unauthorized transitions:
  ```systemverilog
  assert property (
      (PSEL && PENABLE && PWRITE && (s_apb_addr == `REG_GPIOLOCK)) |-> 
      !$past(r_gpio_lock & ~PWDATA)
  )
  else $error("Security violation: Attempt to clear lock bits in r_gpio_lock");
  ```
- **Hardware Policy Checking**: Match implementation against the documented hardware security specification.
- **Runtime Monitoring**: Instrument lock registers to log and flag any writes that attempt to clear set bits.

## Mitigation

The following mitigation is recommended to secure the lock register:

- Modify the register write logic to only allow setting bits:
  ```systemverilog
  r_gpio_lock <= r_gpio_lock | PWDATA;
  ```
- Ensure this register is reset only by hardware or external reset signals.
- Protect access to `REG_GPIOLOCK` via privilege-level enforcement in firmware.
- Include additional assertions and coverage models in the verification plan.

## Summary

The ability to clear GPIO lock bits via software represents a severe breach of expected hardware security policy. If intentional, this logic constitutes a hardware Trojan that undermines system integrity by enabling unauthorized control of GPIO configurations. Immediate mitigation and verification updates are necessary to ensure security assurances in any system deploying this component.
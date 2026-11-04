# Hardware Trojans in an AES-128 Core

This folder contains a Trojan-free AES-128 hardware implementation and three versions of it with a hardware Trojan inserted. Your job in the assignment (`../Questions.md`) is to understand how each Trojan works, assess whether ordinary functional verification would find it, and build testbenches that do find it.

## Quick reference

| ID | Trojan | Folder |
|----|--------|--------|
| **T1** | Functional Trojan | `Functional_Trojan/` |
| **T2** | Timing-dependent functional Trojan | `Functional_Timing_Trojan/` |
| **T3** | Degradation Trojan | `Degradation_attack_Trojan/` |

The Trojan-free reference design is in `AES/`. Use the IDs T1, T2, and T3 in all of your answers.

---

## 1. Background: what is a hardware Trojan?

A **hardware Trojan** is a malicious, intentional modification of an integrated circuit or a hardware IP block that makes it behave in a way its designers and users did not intend. Modern chips are rarely designed and manufactured by a single trusted party. Third-party IP cores, outsourced fabrication, and third-party design tools all give an adversary an opportunity to add or change logic [2, 3].

Hardware Trojans are usually described in terms of two parts [2]:

- **Trigger:** the condition that activates the Trojan. A Trojan can be *always on* or *conditionally triggered*. Conditional triggers can be combinational (a rare value on some inputs or internal nets) or sequential (a sequence of events, or a counter reaching a value). Attackers choose rare trigger conditions so the Trojan stays dormant during verification and manufacturing test.
- **Payload:** what the Trojan does once it is triggered. Common payloads change the circuit's function, leak secret information such as a cryptographic key, degrade performance or reliability, or deny service altogether.

**Why Trojans are hard to find.** Functional verification asks "does the design do what the specification says?" A well-designed Trojan does everything the specification says, plus something extra that only happens under conditions the verification never exercises. Exhaustive testing is not an option as this AES core receives 256 new input bits (128-bit plaintext and 128-bit key) on every clock cycle, and sequential triggers depend on the history of those inputs too. Research on detection therefore looks at logic testing that deliberately targets rare conditions, side-channel measurements such as power, delay, and electromagnetic emissions, analysis of the design itself to find suspicious, rarely-used logic, and run-time monitoring [2, 3].

## 2. The three Trojan classes in this assignment

### 2.1 Functional Trojans
A functional Trojan changes the *logical* behavior of the circuit: once triggered, the outputs are different from what the specification requires. In cryptographic hardware, a particularly damaging functional payload is **key leakage**: if the key ever appears at an output, every message protected with that key is compromised. A common trigger is a "cheat code," a specific input value or input sequence that is very unlikely to occur by chance but that the attacker can apply on purpose. Because the effect is visible at the outputs, standard logic testing *can* detect a functional Trojan, but only if the test happens to activate the trigger.

### 2.2 Timing-dependent functional Trojans
A timing-dependent Trojan adds a notion of time to the trigger, usually a counter that counts clock cycles or events since power-up. The Trojan stays dormant until the counter reaches a threshold. Such Trojans are often called **time bombs**. They are hard to catch in simulation because simulations typically run for a limited number of cycles after reset, far fewer than a chip experiences in the field. Combining a time condition with an input-based trigger lowers the activation probability further. The payload may also be brief, so a test that checks outputs only occasionally can miss it even after activation.

### 2.3 Degradation Trojans
A degradation Trojan does not necessarily produce wrong results. Instead, it reduces the performance or reliability of the circuit: it adds stalls or latency, lowers throughput, increases power consumption, or shortens the device's lifetime. At the physical level, reliability Trojans have been proposed that subtly modify the fabrication process so that transistors wear out faster through aging mechanisms such as NBTI and HCI. At the RTL level, a similar effect can be achieved with extra logic that, for example, stalls the datapath. Since the output values can still be correct eventually, a test that only compares values may pass. Detection requires checking **timing** (latency, throughput, cycle-accurate output) or measuring parametric behavior.

## 3. The designs in this folder

- **`AES/` (Trojan-free).** The AES-128 core used in Trust-Hub's AES-T1000 benchmark [1,4,5], with the original Trust-Hub Trojan removed. The core is a fully pipelined design by Homer Hsing.
- **`Functional_Trojan/` (T1).** The same core with a functional Trojan inserted.
- **`Functional_Timing_Trojan/` (T2).** The same core with a timing-dependent functional Trojan inserted.
- **`Degradation_attack_Trojan/` (T3).** The same core with a degradation Trojan inserted.

Each Trojan was inserted by modifying the RTL of the clean core. Finding where each Trojan is, what activates it, and what it does is part of the assignment.

Each folder contains the RTL (`aes_128.v`, `round.v`, `table.v`) and a basic testbench (`test_aes_128.v`). The testbench is the same in all four folders: it applies one key and five plaintexts and records a waveform. It does not check the results.

## 4. Running the simulations

Use the starter notebook `HT_Starter_Notebook.ipynb` in the top-level assignment folder. It runs in Google Colab or local Jupyter and:

1. installs Icarus Verilog and the `vcdvcd` waveform reader;
2. pulls the Verilog files from this folder into one working folder per design (`designs/AES`, `designs/T1`, `designs/T2`, `designs/T3`);
3. compiles and runs the provided testbench on each design and plots the waveforms;
4. provides a testbench template for Part C that runs on several designs at once.

Each design consists of exactly three RTL files: `aes_128.v` (top level and key expansion), `round.v` (the `one_round` and `final_round` modules), and `table.v` (T-tables and S-boxes).

The provided testbench already dumps a waveform (`wave.vcd`) and ends with `$finish`.

Icarus Verilog supports only part of SystemVerilog, so keep testbenches to modules, tasks, functions, `$urandom`, and plain `if`/`$display` checks.

## 5. References and further reading

1. Trust-Hub, Chip-level Trojan benchmarks. https://trust-hub.org/#/benchmarks/chip-level-trojan
2. M. Tehranipoor and F. Koushanfar, "A Survey of Hardware Trojan Taxonomy and Detection," *IEEE Design & Test of Computers*, 2010
3. S. Bhunia, M. S. Hsiao, M. Banga, and S. Narasimhan, "Hardware Trojan Attacks: Threat Analysis and Countermeasures," *Proceedings of the IEEE*, 2014
4. H. Salmani, M. Tehranipoor, and R. Karri, "On Design vulnerability analysis and trust benchmark development", *IEEE Int. Conference on Computer Design (ICCD)*, 2013
5. B. Shakya, T. He, H. Salmani, D. Forte, S. Bhunia, M. Tehranipoor, “Benchmarking of Hardware Trojans and Maliciously Affected Circuits”, *Journal of Hardware and Systems Security (HaSS)*, April 2017

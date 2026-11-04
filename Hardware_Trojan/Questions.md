# Hardware Trojans in an AES-128 Core: Assignment Questions

**Total: 100 points**

| Part | Questions | Points |
|------|-----------|--------|
| A. The Trojan-free AES-128 core | Q1 – Q2 | 16 |
| B. Trojan analysis | Q3 – Q5 | 24 |
| C. Trojan detection (test plans + simulation) | Q6 – Q8 | 60 (20 each) |

Read `Main_Trojans/Readme.md` before you start, and you may use `HT_Starter_Notebook.ipynb` to set up and run all simulations. Throughout this assignment the Trojans are referred to by number:

| ID | Trojan | Folder |
|----|--------|--------|
| **T1** | Functional Trojan | `Main_Trojans/Functional_Trojan/` |
| **T2** | Timing-dependent functional Trojan | `Main_Trojans/Functional_Timing_Trojan/` |
| **T3** | Degradation Trojan | `Main_Trojans/Degradation_attack_Trojan/` |

The Trojan-free reference design is in `Main_Trojans/AES/`.

---

## Part A: The Trojan-free AES-128 core [16 points]
The questions in this section are for the files in `AES/` (the trojan-free version of AES).

### Q1. Pipeline, latency, and throughput [8 points]
  Trace the data path from the `state` and `key` inputs through `s0`, `s1`, …, `s9` to `out`, noting where each round key is XORed in. Count the registers along this path (including the ones inside the `S` and `xS` modules) and determine the **latency**, the number of clock cycles between the clock edge that samples a (`state`, `key`) pair and the clock edge at which the matching ciphertext appears on `out`, and the **throughput**, how much data this module can continuously process. What is the **latency** (in cycles) and the **throughput** (in bits per cycle) of this design? [5 points]

### Q2. Self-checking testbench [8 points]
  `AES/Read_Me.txt` states that `test_aes_128.v` is self-checking, but it is not.
  The same testbench is provided in all four folders. Make it self checking (compare against known answer tests provided by the specification) and run it on `AES`, `T1`, `T2`, and `T3` (Section 5 of the starter notebook) and compare `out` across the four designs. What do you observe, and what does this tell you about how much confidence a passing functional test gives you? [5 points]

---

## Part B: Trojan analysis [24 points]

### Q3. Locate the triggers and payloads [8 points]
  Each Trojan was inserted by modifying the RTL of the clean core. Use `diff` against `AES/` to find the changes in each Trojan folder.
  For each of T1, T2, and T3, identify and report the **trigger** logic, the exact input values that activate it, the order in which they must appear, and any other condition (for example: must they arrive on consecutive clock cycles? does `key` matter? is there a time condition?), and the **payload** logic, which module it lives in and what it does to the circuit's behavior once activated.
  Summarize your findings in one table with the columns: Trojan | trigger values (in order) | additional trigger conditions | payload | duration of the effect (a single cycle, a fixed window, or until power-off). [5 points]

### Q4. T2: timing behavior [8 points]
  **(a)** What is the purpose of the 15-bit counter `count1`? When does it start counting, is it ever reset, and what happens when it overflows? [4 points]
  **(b)** Trace through the logic: If the trigger sequence is detected, what happens to `innocent_var1`, and how long does it take before `innocent_var` is set? [4 points]

### Q5. T3: degradation behavior [8 points]
  **(a)** Explain how the modified `final_round` uses the `trig` input. While `trig` is high, what does `out` show? Are the ciphertexts of plaintexts applied during that window delayed, or are they lost? [4 points]
  **(b)** Compare how `count1` is used in T3 with how it is used in T2 (what starts it, what it counts, what stops it). How long does the degradation last, in clock cycles and in nanoseconds at the testbench's 10 ns clock? [4 points]

---

## Part C: Trojan detection [60 points]

### Scenario (applies to Q6, Q7, and Q8)

You are a verification engineer. You receive each of the AES cores as an **encrypted (black-box) IP**: you can drive `clk`, `state`, and `key` and observe `out`, and nothing else. You cannot see the RTL or any internal signal, and nobody has told you the core contains a Trojan.

Each of Q6–Q8 has the same four parts, applied to one Trojan. So you will answer all the three questions for Trojan T1, then all three questions again for T2, and then again for T3.

**(a) Black-box detection likelihood [5 points].**
Write the functional verification plan you would realistically use for an AES-128 core you had no reason to distrust (for example: FIPS-197 known-answer tests, a few thousand constrained-random plaintext/key pairs checked against a reference model, and some directed corner cases). It doesn't have to be extremely detailed like what you would expect in a Verification course, just the high level ideas of how you would approach this.

Then estimate the probability that this plan would both **activate** the Trojan and **observe** its effect at `out`.
Support your answer with a calculation (for example, the probability of hitting the trigger per clock cycle under uniformly random stimulus, and the expected number of cycles until activation) and with a qualitative argument (which common verification habits make detection more or less likely). If you conclude that detection is practically impossible, justify that conclusion quantitatively.

**(b) Targeted test plan [5 points].**
Now you *do* know how the Trojan works. Write a specialized test plan that will catch it. Again, it doesn't have to be extremely detailed like what you would expect in a Verification course, just the high level ideas.
Specify:
- the stimulus (values, order,  etc.);
- the reference behavior you compare against;
- what you check, when (every cycle, or only at certain cycles), and the exact pass/fail criterion;
- the observable symptom that indicates the Trojan.

**(c) Testbench implementation and simulation [10 points].**
Implement your plan in a **Jupyter Notebook** using **Icarus Verilog**. You may start from `HT_Starter_Notebook.ipynb`.
- Write a Verilog or SystemVerilog testbench, starting from the template in Section 6 of the starter notebook (it already includes the clock, the design instance, the waveform dump, and `$finish`), and run it on the Trojan design.
- The testbench must be **self-checking**: it prints an explicit `TROJAN DETECTED` message (with the simulation time or cycle number and the observed versus expected values) when the misbehavior occurs, and `PASS` otherwise.
- Run the **same testbench** against the Trojan-free design in `AES/` and show that it reports `PASS`, i.e., your test has no false positives.
- Include a waveform plot (`plot_waves`) zoomed in on the window in which the Trojan is detected.
- The notebook must run top to bottom in a fresh session.

Tips: Icarus Verilog supports only part of SystemVerilog. Stick to modules, tasks, functions, `$urandom`, and plain `if`/`$display` checks. If you instantiate the Trojan-free core as a reference model in the same testbench, you may have to rename all of its modules (for example, with a `ref_` prefix) to avoid name collisions with the Trojan version.

---

### Q6. Detecting T1 (Functional Trojan) [20 points]
Answer parts (a)–(d) for **T1**. In addition, your answer must:
- identify exactly what value appears on `out` after activation, and demonstrate it in simulation;
- show whether the misbehavior persists after the input stops matching the trigger sequence.

### Q7. Detecting T2 (Timing-dependent functional Trojan) [20 points]
Answer parts (a)–(d) for **T2**. In addition, your answer must:
- in part (a), explain how the length of a typical simulation and the frequency with which outputs are checked affect the chance of observing a payload that may last only a short time;
- in part (b), justify how many clock cycles you must simulate, and address the case where the trigger sequence arrives *after* the internal counter has passed 10,000;
- in part (c), demonstrate at least one activation in simulation, and check `out` on **every** clock cycle.

### Q8. Detecting T3 (Degradation Trojan) [20 points]
Answer parts (a)–(d) for **T3**. In addition, your answer must:
- explain, in part (a), why a testbench that only checks that the correct ciphertext *eventually* appears could pass this core;
- in parts (b) and (c), measure latency and throughput rather than only output values: use the latency you derived in Q1 as the expected value, stream a new plaintext every clock cycle, and use a scoreboard to report the measured latency and the number of missing or stale results before and after activation;
- state the numerical threshold you use to declare the Trojan detected and justify it.

---

## Feedback (Optional)

These questions are worth 0 points. This is to aid our research in the effectiveness of this assignment, and all data will be anonymized. You may choose to not complete this question and you will not be penalized for it. Nor will you get any bonus points for completing this question. This is completely voluntary and has no effect on the score for this assignment, future assignments, and the course grade.

You will also be given a consent form to use anonymized data from the rest of the assignment to guage the effectiveness of this assignment, if it has already not been done so. Again, that will have more detailed version of the voluntary nature of it, but you will not be penalized in any manner for not providing consent.

#### Q9 (Optional)
How long did it take for you to complete the assignment?

#### Q10 (Optional)
Was the assignment easy to understand and follow? If not, what area needs improvement?
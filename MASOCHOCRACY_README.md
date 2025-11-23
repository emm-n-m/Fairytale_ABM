# Masochocracy Simulation - User Guide

## Overview

This NetLogo simulation tests Queen Amethyst's Masochocracy political system, where leaders must submit to ritual humiliation from their subordinates. The core hypothesis: **requiring leaders to endure humiliation from those they govern will naturally select for competent, low-authoritarian individuals** - precisely the opposite of what traditional power structures produce.

## Installation & Setup

1. Download and install NetLogo from: https://ccl.northwestern.edu/netlogo/
2. Open the `masochocracy.nlogo` file
3. If the interface doesn't load automatically, manually add the interface elements from `masochocracy_interface.txt`

## Core Mechanics

### Agent Traits

Each agent has three key attributes:

- **Competence (0-100)**: Ability to perform their role effectively
- **Authoritarianism (0-100)**: Desire to dominate others
- **Humiliation Tolerance**: Calculated as:
  ```
  tolerance = (competence × competence_factor) - (authoritarianism × authoritarian_penalty)
  ```

### The Masochocracy Mechanism

**Promotion**: Agents compete for leadership based on:
- Authoritarianism (drive to seek power)
- Competence (ability to rise)

**Survival**: Once in power, leaders must endure humiliation:
- Subordinates ritually dominate their leaders
- Humiliation accumulates each tick
- More authoritarian leaders perceive MORE humiliation from the same treatment
- When `perceived_humiliation > humiliation_tolerance`, the leader steps down

**The Trap**: Authoritarian individuals desperately want power but can't tolerate the submission required to keep it.

## Key Parameters

### Population
- **num-agents** (10-500): Total agent population. Larger = more complex dynamics.

### Tolerance Calculation
- **competence-tolerance-factor** (0-2): How much competence helps endure humiliation
  - Higher = competent people survive leadership longer
  - Recommended: 0.5-1.0
  
- **authoritarianism-penalty-factor** (0-2): How much authoritarianism sabotages tolerance
  - Higher = authoritarian leaders crack faster
  - Recommended: 1.0-1.5

### Humiliation Dynamics
- **humiliation-base-rate** (0.1-5): Base humiliation accumulated per subordinate per tick
  - Higher = leaders burn out faster
  - Recommended: 1.0-2.0

### Promotion System
- **promotion-frequency** (5-50 ticks): How often promotion opportunities occur
  - Lower = more rapid turnover
  - Recommended: 15-25

- **promotion-authoritarian-weight** (0-1): How much desire for power drives promotion
  - Higher = more power-hungry individuals rise
  - Recommended: 0.4-0.7

- **promotion-competence-weight** (0-1): How much competence drives promotion
  - Higher = more meritocratic selection
  - Recommended: 0.3-0.6

- **max-leaders-per-level** (1-20): Maximum leaders at each hierarchical level
  - Higher = more complex organizational structure

## Experimental Hypotheses

### Primary Hypothesis
**Masochocracy naturally selects for low-authoritarian, high-competence leaders over time.**

Expected observations:
- Initial leaders will be high-authoritarian (they seek power aggressively)
- These leaders will quickly burn out and step down
- Over time, average leader authoritarianism should DECREASE
- Average leader competence should INCREASE or remain stable

### Secondary Hypotheses

1. **Stability increases over time**: As authoritarian individuals learn they can't survive leadership, fewer will seek it
   - Monitor: Stepdown rate should decrease over time
   - Monitor: Average time-in-position should increase

2. **The competence floor**: There exists a minimum competence level below which NO agent can survive leadership
   - Experiment: Decrease competence-tolerance-factor and observe collapse
   - Expected: System becomes unstable with very low factor

3. **The authoritarian ceiling**: There exists a maximum authoritarianism level above which leadership is impossible
   - Monitor: Check if high-authoritarian agents (>80) ever achieve stable leadership
   - Expected: They should cycle rapidly through promotion → stepdown

4. **Optimal leader profile emerges**: The system should converge toward a specific trait combination
   - Hypothesis: Leaders will cluster around moderate-high competence (60-80) and low authoritarianism (20-40)

## Experimental Protocols

### Baseline Run
1. Use default parameters
2. Run for 500 ticks
3. Observe: Do leader traits shift toward low-authoritarian, high-competence?

### Stress Test: High Humiliation Pressure
1. Set `humiliation-base-rate` to 3.0
2. Set `authoritarianism-penalty-factor` to 1.5
3. Hypothesis: Even low-authoritarian leaders struggle; only highest-competence survive

### Stress Test: Power-Hungry Promotions
1. Set `promotion-authoritarian-weight` to 0.8
2. Set `promotion-competence-weight` to 0.2
3. Hypothesis: System promotes wrong people; massive turnover; potential collapse

### Tolerance Test: Can Authoritarians Survive?
1. Set `authoritarianism-penalty-factor` to 0.3
2. Hypothesis: Authoritarians can now endure leadership; system fails to filter them out

### Meritocracy Comparison
1. Set `promotion-authoritarian-weight` to 0.1
2. Set `promotion-competence-weight` to 0.9
3. Hypothesis: Best leaders selected immediately, but perhaps fewer seek leadership

## What to Watch

### Plots

1. **Leader Traits Over Time**: 
   - Look for decreasing authoritarianism trend
   - Competence should remain stable or increase
   - Convergence = system working as intended

2. **Leadership Distribution**: 
   - How many agents reach each level?
   - Does it form a pyramid or something else?

3. **Humiliation Stress**: 
   - Distribution of stress among current leaders
   - Leaders near threshold = about to break

4. **Time in Position**:
   - Are tenures increasing over time?
   - Stable system = longer average tenure

### Monitors

- **Stepdown Rate**: Should decrease as wrong people stop seeking power
- **Avg Leader Authoritarianism**: Should trend downward
- **Avg Leader Competence**: Should remain high or increase

## Theoretical Implications

If the simulation supports the primary hypothesis, it suggests:

1. **Power-seeking is self-defeating in Masochocracy**: The very trait that drives you to seek leadership sabotages your ability to keep it

2. **Natural selection without violence**: Unlike Dracodemocracy (dragons eat bad leaders), Masochocracy uses psychological pressure to filter out authoritarians

3. **The humiliation must be real**: If subordinates can't actually impose costs on leaders, the filtering mechanism fails

4. **Potential real-world applications**:
   - Corporate structures with mandatory subordinate feedback power
   - Political systems with genuine accountability to constituents
   - ANY hierarchy where leaders must regularly submit to those they govern

## Queen Amethyst's Predicted Drawback

From the document: "It carries the drawback that I will have to spend too much time being restrained and dominated, with me being the Queen and thus having to sub for everyone."

This simulation doesn't model the Queen's specific complaint (her unique position at the top of the hierarchy), but you could explore:
- What if there's one agent who must sub to ALL others?
- Set one agent's leadership-level to max and track their humiliation accumulation
- Does the system still work, or does the top position become untenable?

## Extensions & Modifications

Potential enhancements to explore:

1. **Learning**: Agents learn from observing others' failures and adjust their promotion-seeking behavior

2. **Rebellion**: If humiliation exceeds tolerance by too much, subordinates stage a coup

3. **Corruption**: Leaders can reduce humiliation by bribing or intimidating subordinates (breaking the system)

4. **Variable subordinate count**: Some leaders have more subordinates than others (CEOs vs middle managers)

5. **Competence development**: Agents in leadership positions gain competence over time

6. **Authoritarianism is dynamic**: Being in power increases authoritarianism; being humiliated decreases it

## Comparison to Traditional Systems

To truly test Masochocracy's superiority, you'd need to build comparison simulations:

- **Standard Democracy**: Voters select leaders based on perceived competence/charisma; no humiliation mechanism
- **Autocracy**: One leader, no humiliation, stays until death/coup
- **Meritocracy**: Pure competence-based selection, no humiliation

Then compare:
- Average leader competence over time
- System stability (variance in leadership)
- Ability to remove bad leaders

## Known Limitations

1. **Simplified promotion**: Real leadership selection involves networking, charisma, luck
2. **Binary tolerance**: Real leaders might endure humiliation strategically, not mechanically
3. **No coalition building**: Real authoritarians band together to protect each other
4. **Uniform subordinates**: All subordinates impose equal humiliation; reality varies

## Advanced Analysis

For rigorous testing, run multiple simulations varying:
- Initial trait distributions
- Parameter combinations
- Random seeds

Then perform statistical analysis:
- Does leader authoritarianism SIGNIFICANTLY decrease? (t-test)
- What's the correlation between competence and leadership tenure?
- Can you predict steady-state leader traits from parameters?

## Final Thoughts

The beauty of Masochocracy is its elegant inversion: **the selection mechanism for power becomes the filtering mechanism against power-abuse.** Traditional systems let authoritarians reach power, then try to constrain them (constitutions, checks and balances). Masochocracy constrains them THROUGH the mechanism of reaching power.

Whether this works in practice depends on whether the humiliation is:
1. **Real** (subordinates can actually impose costs)
2. **Unavoidable** (leaders can't delegate or escape it)
3. **Proportional** (enough to deter authoritarians, not so much it deters everyone)

This simulation lets you test those conditions mathematically.

---

*"After all, they are going to get whipped hard (or worse) if they do."* - Queen Amethyst

Good luck with your experiments in applied theoretical arcanoprobability!

# Fuzzy Emergency Braking for an Autonomous Vehicle (First-Order Sugeno FIS)

A first-order Takagi-Sugeno fuzzy inference system in MATLAB that decides the **steering angle** and the **brake pressure** of a vehicle from three distance sensors and its current speed.

Sugeno was chosen over Mamdani because its weighted-average defuzzification avoids the costly centroid computation, which makes it better suited to embedded, real-time use.

Course project for *Fundamentals of Computational Intelligence*. The full report (with all figures) is in [`Fuzzy_Emergency_Braking_Report_EN.pdf`](Fuzzy_Emergency_Braking_Report_EN.pdf).

## System

| | Variable | Range | Membership functions |
|---|---|---|---|
| Input | Front distance | 0-10 m | Collision (trapezoid), Near (triangle), Far (trapezoid) |
| Input | Right distance | 0-5 m | Closed, Open (trapezoids) |
| Input | Left distance | 0-5 m | Closed, Open (trapezoids) |
| Input | Speed | 0-2 m/s | Slow, Fast (trapezoids) |
| Output | Steering angle | -45° to +45° | linear (Sugeno) |
| Output | Brake | 0-100 % | linear (Sugeno) |

- 9 rules, AND implemented as `min`
- Each rule has its own linear output equation for steering and for braking:
  `Z = a·Front + b·Right + c·Left + d·Speed + e`
- The speed coefficient `d` makes the response speed-dependent (e.g. harder braking and faster steering at higher speed)
- Final output: weighted average, `sum(w_i · Z_i) / sum(w_i)`

### Rule groups

| Rules | Situation | Behaviour |
|---|---|---|
| R1-R4 | Front blocked (critical) | Sharp steering toward the free side, heavy braking; if boxed in, steering locked at 0 and 100 % brake |
| R5-R8 | Front near (controllable) | Soft steering and mild braking |
| R9 | Front far and open (safe) | Straight ahead, minimal braking |

## Scenarios

Inputs are `[front, right, left, speed]`. Output values are read from the MATLAB Rule Viewer (see the report).

| # | Situation | Inputs | Steering | Brake |
|---|---|---|---|---|
| 1 | Certain collision, escape route on the right | 0.3, 3.0, 0.5, 1.5 | ≈ 39° (right) | ≈ 95 % |
| 2 | Completely boxed in | 0.3, 0.5, 0.5, 0.5 | 0° | 100 % |
| 3 | Obstacle at medium distance | 3.0, 3.0, 0.5, 1.0 | ≈ 11° (right) | ≈ 32 % |
| 4 | Open highway, high speed | 8.0, 1.0, 1.0, 1.8 | 0° | ≈ 8.6 % |

The report also contains a sweep of steering and brake output against front distance.

## Naming used in the code and figures

Variable and label names in the MATLAB code and in the screenshots are transliterated Persian:

| Code | Meaning | Code | Meaning |
|---|---|---|---|
| `Jelo` | Front | `Barkhord` | Collision |
| `Raast` / `Rast` | Right | `Nazdik` | Near |
| `Chap` | Left | `Door` | Far |
| `Soraat` | Speed | `Baste` / `Baaz` | Closed / Open |
| `CharkheshFarmaan` | Steering | `Kond` / `Tond` | Slow / Fast |
| `Tormoz` | Brake | | |

## Files

- `<main_file>.m`: builds the FIS, runs the scenarios, plots membership functions and the sweep
- `Fuzzy_Emergency_Braking_Report_EN.pdf`: full report (English)

## How to run

Requires MATLAB with the Fuzzy Logic Toolbox. Open the main script and run it.

## Limitations

- Rule-consequent coefficients were set by hand, not learned from data (e.g. with ANFIS)
- Evaluated on static input-output scenarios only; there is no closed-loop vehicle simulation
- Only four scenarios were tested

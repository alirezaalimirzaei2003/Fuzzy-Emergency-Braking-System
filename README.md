# Fuzzy Emergency Braking for an Autonomous Vehicle (First-Order Sugeno FIS)

A first-order Takagi-Sugeno fuzzy inference system in MATLAB that decides the **steering angle** and the **brake pressure** of a vehicle from three distance sensors and its current speed.

Sugeno was chosen over Mamdani because its weighted-average defuzzification avoids the costly centroid computation, which makes it better suited to embedded, real-time use.

Course project for *Fundamentals of Computational Intelligence*. The full report, with all figures, is in [`Fuzzy_Emergency_Braking_Report_EN.pdf`](Fuzzy_Emergency_Braking_Report_EN.pdf) (English translation of the original Persian report).

## System

| | Variable | Range | Membership functions |
|---|---|---|---|
| Input | Front distance | 0-10 m | Collision (trapezoid), Near (triangle), Far (trapezoid) |
| Input | Right distance | 0-5 m | Closed, Open (trapezoids) |
| Input | Left distance | 0-5 m | Closed, Open (trapezoids) |
| Input | Speed | 0-2 m/s | Slow, Fast (trapezoids) |
| Output | Steering angle | -45° to +45° (positive = right) | linear (Sugeno) |
| Output | Brake | 0-100 % | linear (Sugeno) |

- 9 rules; AND is the product of the membership degrees (the default of MATLAB's `sugfis`)
- Each rule has its own linear output equation for steering and for braking:
  `Z = a·Front + b·Right + c·Left + d·Speed + e`
- The speed coefficient `d` makes the response speed-dependent (harder braking and faster steering at higher speed)
- Final output: weighted average, `sum(w_i · Z_i) / sum(w_i)`

## Rules

Front = distance ahead, Right/Left = side distances, Speed in m/s. "Any" means the input is not used by the rule.

| Rule | Front | Right | Left | Steering Z (deg) | Brake Z (%) | Behaviour |
|---|---|---|---|---|---|---|
| R1 | Collision | Open | Closed | 3·Speed + 35 | 10·Speed + 80 | Escape right, heavy braking |
| R2 | Collision | Closed | Open | -3·Speed - 35 | 10·Speed + 80 | Escape left, heavy braking |
| R3 | Collision | Open | Open | 2·Speed + 20 | 8·Speed + 75 | Turn right by default, heavy braking |
| R4 | Collision | Closed | Closed | 0 | 100 | Trapped: steering locked, full brake |
| R5 | Near | Open | Closed | -3·Front + 5·Speed + 15 | -2·Front + 8·Speed + 30 | Soft turn right, moderate braking |
| R6 | Near | Closed | Open | 3·Front - 5·Speed - 15 | -2·Front + 8·Speed + 30 | Soft turn left, moderate braking |
| R7 | Near | Closed | Closed | 0 | -3·Front + 10·Speed + 60 | Slow down firmly, no steering |
| R8 | Near | Open | Open | -2·Front + 3·Speed + 10 | -Front + 5·Speed + 25 | Gentle drift right, light braking |
| R9 | Far | Any | Any | 0 | 2·Speed + 5 | Straight ahead, minimal braking |

Rule groups: R1-R4 are the critical situations (front blocked), R5-R8 the controllable ones (front near), and R9 the safe one (front far and open).

## Scenarios

Inputs are `[front, right, left, speed]`. Output values match the MATLAB Rule Viewer screenshots in the report.

| # | Situation | Inputs | Steering | Brake |
|---|---|---|---|---|
| 1 | Certain collision, escape route on the right | 0.3, 3.0, 0.5, 1.5 | ≈ 39.5° (right) | ≈ 95 % |
| 2 | Completely boxed in | 0.3, 0.5, 0.5, 0.5 | 0° | 100 % |
| 3 | Obstacle at medium distance | 3.0, 3.0, 0.5, 1.0 | ≈ 11° (right) | ≈ 32 % |
| 4 | Open highway, high speed | 8.0, 1.0, 1.0, 1.8 | 0° | ≈ 8.6 % |

### Output versus front distance

With right = 3 m, left = 0.5 m and speed = 1 m/s, the system gives about 38° of steering and 90 % brake when the obstacle is closer than 1 m. At 1.5 m this drops to about 15° and 35 %, at 4 m to about 8° and 30 %, and from 5 m onwards the steering is 0° and the brake about 7 %. The sweep is plotted in the report and by the script.

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

## Repository contents

```
Fuzzy_Emergency_Braking_System/
├── Fuzzy_Emergency_Braking_System_Alireza_Alimirzaei.m   main script
├── EmergencyBrakingFIS.fis                                the FIS (plain text)
└── EmergencyBrakingFIS.mat                                the same FIS as a MATLAB variable
Fuzzy_Emergency_Braking_Report_EN.pdf                      full report
README.md
```

- The script builds the FIS, saves it as the `.fis` and `.mat` files, evaluates the four scenarios, plots the membership functions with the scenario inputs marked, and sweeps the front distance.
- The `.fis` file can be opened directly in the Fuzzy Logic Designer app without running the script.

## How to run

Requires MATLAB R2018b or newer with the Fuzzy Logic Toolbox.

1. Open MATLAB in the `Fuzzy_Emergency_Braking_System` folder.
2. Run `Fuzzy_Emergency_Braking_System_Alireza_Alimirzaei.m`.
3. The script writes the `.fis` and `.mat` files to the current folder, prints the result of each scenario (steering angle with direction, and brake pressure), and opens the membership-function figures and the sweep plot.
4. The last two lines open the Rule Viewer and the Fuzzy Logic Designer; comment them out if you do not need the windows.

## Limitations

- Rule-consequent coefficients were set by hand, not learned from data (e.g. with ANFIS)
- Speed does not appear in any rule antecedent: its membership functions are defined but unused, and speed only affects the outputs through the coefficients of the linear equations
- Evaluated on static input-output scenarios only; there is no closed-loop vehicle simulation
- Only four scenarios were tested
- The figures in the report were produced with transliterated Persian labels (see the naming table above)

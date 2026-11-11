% Extra assignment: first-order Sugeno fuzzy system
% Topic: emergency braking and navigation of an autonomous vehicle (2 outputs)
% Inputs:  front / right / left distance (lidar sensors) + current vehicle speed
% Outputs: steering angle + brake pressure
%
% Naming note: variable and membership-function names are transliterated Persian:
%   Jelo = Front, Raast = Right, Chap = Left, Soraat = Speed,
%   Barkhord = Collision, Nazdik = Near, Door = Far,
%   Baste = Closed, Baaz = Open, Kond = Slow, Tond = Fast,
%   CharkheshFarmaan = Steering, Tormoz = Brake
%
% Requires MATLAB R2018b or newer with the Fuzzy Logic Toolbox.

clear; clc; close all;

% Build the Sugeno fuzzy system (AND = product, the default of sugfis)
fis = sugfis('Name','Tormoz_Ezterari');
fis.AndMethod = 'prod';

%% INPUTS

% 1) Front distance (m) - front sensor
fis = addInput(fis,[0 10],'Name','Jelo');
% Obstacle between 0 and 1.5 m -> certain collision (Barkhord)
fis = addMF(fis,'Jelo','trapmf',[0 0 0.5 1.5],'Name','Barkhord');
% Obstacle between 1 and 5 m -> near (Nazdik)
fis = addMF(fis,'Jelo','trimf', [1 3 5],       'Name','Nazdik');
% Obstacle farther than 4 m -> road is open and safe (Door)
fis = addMF(fis,'Jelo','trapmf',[4 6 10 10],   'Name','Door');

% 2) Right distance (m) - right sensor
fis = addInput(fis,[0 5],'Name','Raast');
% Obstacle under 1.5 m on the right -> path closed (Baste)
fis = addMF(fis,'Raast','trapmf',[0 0 0.5 1.5],'Name','Baste');
% Obstacle above 1 m -> path open (Baaz)
fis = addMF(fis,'Raast','trapmf',[1 2 5 5],    'Name','Baaz');

% 3) Left distance (m) - left sensor
fis = addInput(fis,[0 5],'Name','Chap');
% The same membership functions as the right side are used for the left side
fis = addMF(fis,'Chap','trapmf',[0 0 0.5 1.5],'Name','Baste');
fis = addMF(fis,'Chap','trapmf',[1 2 5 5],    'Name','Baaz');

% 4) Current speed (m/s)
fis = addInput(fis,[0 2],'Name','Soraat');
% Low speed (below 0.8) -> Kond (Slow)
fis = addMF(fis,'Soraat','trapmf',[0 0 0.3 0.8],  'Name','Kond');
% High speed (above 0.6) -> Tond (Fast)
fis = addMF(fis,'Soraat','trapmf',[0.6 1.2 2 2],  'Name','Tond');
% Note: speed is not used in any rule antecedent (see the rule list below);
% it only enters the outputs through the linear coefficients.

%% OUTPUTS (Sugeno linear equations)
% In a first-order Sugeno system the outputs are not constants but linear equations.

% Output ranges: -45 to 45 degrees for steering, 0 to 100 percent for the brake
% Sign convention: positive steering = turn right, negative = turn left
fis = addOutput(fis,[-45 45],'Name','CharkheshFarmaan');
fis = addOutput(fis,[0 100], 'Name','Tormoz');

% Coefficients of each linear equation, in order: [Jelo, Raast, Chap, Soraat, constant]
% Output = (a*Jelo) + (b*Raast) + (c*Chap) + (d*Soraat) + constant
CharkheshFarmaanParams = {
    [0  0  0  3  35];    % R1: certain collision + right open -> default 35 deg to the right + (3 * Speed)
    [0  0  0 -3 -35];    % R2: certain collision + left open  -> default 35 deg to the left - (3 * Speed)
    [0  0  0  2  20];    % R3: certain collision + both open  -> turn right with a gentler slope
    [0  0  0  0   0];    % R4: certain collision + both closed -> steering 0 (brake only)
    [-3 0  0  5  15];    % R5: near obstacle + right open -> dynamic formula based on distance
    [3  0  0 -5 -15];    % R6: near obstacle + left open  -> dynamic formula based on distance
    [0  0  0  0   0];    % R7: near obstacle + both closed -> steering 0
    [-2 0  0  3  10];    % R8: near obstacle + both open -> soft turn to the right
    [0  0  0  0   0];    % R9: far (safe) -> zero steering (straight motion)
};

TormozParams = {
    [0  0  0 10  80];    % R1: severe braking 80% + (10 * Speed)
    [0  0  0 10  80];    % R2: severe braking
    [0  0  0  8  75];    % R3: severe braking
    [0  0  0  0 100];    % R4: 100% full braking (trap)
    [-2 0  0  8  30];    % R5: softer braking because the path is open
    [-2 0  0  8  30];    % R6: softer braking
    [-3 0  0 10  60];    % R7: semi-severe braking
    [-1 0  0  5  25];    % R8: light braking
    [0  0  0  2   5];    % R9: a slight brake if the speed is very high
};

% Add these linear equations as the output membership functions
for i = 1:9
    fis = addMF(fis,'CharkheshFarmaan','linear',CharkheshFarmaanParams{i},'Name',['CharkheshFarmaanR' num2str(i)]);
    fis = addMF(fis,'Tormoz','linear',TormozParams{i},'Name',['TormozR' num2str(i)]);
end

%% RULES
% Format: [Jelo Raast Chap Soraat | steering Brake | weight | AND(1)]
% Input index 0 = "don't care" (this sensor does not need to be checked)
ruleList = [
    1  2  1  0   1  1   1  1;   % R1: Jelo(Barkhord), Raast(Baaz),  Chap(Baste)
    1  1  2  0   2  2   1  1;   % R2: Jelo(Barkhord), Raast(Baste), Chap(Baaz)
    1  2  2  0   3  3   1  1;   % R3: Jelo(Barkhord), Raast(Baaz),  Chap(Baaz)
    1  1  1  0   4  4   1  1;   % R4: Jelo(Barkhord), Raast(Baste), Chap(Baste)
    2  2  1  0   5  5   1  1;   % R5: Jelo(Nazdik),   Raast(Baaz),  Chap(Baste)
    2  1  2  0   6  6   1  1;   % R6: Jelo(Nazdik),   Raast(Baste), Chap(Baaz)
    2  1  1  0   7  7   1  1;   % R7: Jelo(Nazdik),   both closed
    2  2  2  0   8  8   1  1;   % R8: Jelo(Nazdik),   both open
    3  0  0  0   9  9   1  1;   % R9: Jelo(Door) -> other sensors are "don't care"
];
fis = addRule(fis,ruleList);

%% SAVE THE FIS FILES
save('EmergencyBrakingFIS.mat','fis');
writeFIS(fis,'EmergencyBrakingFIS.fis');

%% SCENARIOS
% Each row: [Front Right Left Speed]
scenarios = [
    0.3  3.0  0.5  1.5;   % Scenario 1: certain collision, right open, high speed
    0.3  0.5  0.5  0.5;   % Scenario 2: certain collision, everything closed (trap)
    3.0  3.0  0.5  1.0;   % Scenario 3: near obstacle, right open, medium speed
    8.0  1.0  1.0  1.8;   % Scenario 4: completely open path, high speed
];
names = {'Collision + escape route on the right', 'Collision + fully boxed in (trap)', ...
         'Near obstacle + right open', 'Open road and high speed'};
inputNames = {'Jelo (front distance)', 'Raast (right distance)', 'Chap (left distance)', 'Soraat (speed)'};

% One figure per scenario, so that all membership-function plots stay visible
for k = 1:size(scenarios,1)

    figName = sprintf('Scenario %d: %s', k, names{k});
    figure('Name', figName, 'NumberTitle', 'off', 'Position', [100+(k*20), 100+(k*20), 900, 600]);
    sgtitle(sprintf('Fuzzification in Scenario %d: %s', k, names{k}));

    for i = 1:4
        subplot(2, 2, i);
        plotmf(fis, 'input', i);
        hold on;

        % The dashed line marks the input value and the membership degrees it cuts
        current_val = scenarios(k, i);
        xline(current_val, 'r--', 'LineWidth', 2);

        title(sprintf('%s = %.1f', inputNames{i}, current_val));
    end
end

%% EVALUATE THE OUTPUTS FOR EACH SCENARIO
fprintf('=== Results of the Sugeno fuzzy system ===\n\n');
for k = 1:size(scenarios,1)

    out = evalfis(fis, scenarios(k,:));

    fprintf('Scenario %d (%s):\n', k, names{k});
    fprintf('  Input  -> Jelo=%.1f  Raast=%.1f  Chap=%.1f  Soraat=%.1f\n', scenarios(k,:));

    fprintf('  Output -> Steering angle = %.2f deg (%s) | Brake pressure = %.1f%%\n\n', ...
        out(1), ternaryDir(out(1)), out(2));
end

%% OUTPUT SENSITIVITY ANALYSIS
% Examines the non-linear behavior of the system
Rangejelo = linspace(0,10,100)';   % 100 points of front distance from 0 to 10 m
fixedInputs = [3.0 0.5 1.0];       % Assumed: right open (3 m), left closed (0.5 m), speed 1 m/s
farman1 = zeros(size(Rangejelo));
Tormoz2 = zeros(size(Rangejelo));

for i = 1:length(Rangejelo)
    o = evalfis(fis,[Rangejelo(i) fixedInputs]);
    farman1(i) = o(1);
    Tormoz2(i) = o(2);
end

figure('Name', 'Output sensitivity analysis', 'NumberTitle', 'off', 'Position', [150, 150, 800, 600]);
subplot(2,1,1);
plot(Rangejelo, farman1, 'b-','LineWidth',2);
xlabel('Front distance (m)'); ylabel('Steering angle (deg)');
title('Steering angle vs. front obstacle distance (Right=3, Left=0.5, Speed=1; positive = right)'); grid on;

subplot(2,1,2);
plot(Rangejelo, Tormoz2, 'r-','LineWidth',2);
xlabel('Front distance (m)'); ylabel('Brake pressure (%)');
title('Brake pressure vs. front obstacle distance'); grid on;

%% OPTIONAL: open the interactive tools (comment these out if not needed)
ruleview(fis);                                   % rule viewer window
fuzzyLogicDesigner('EmergencyBrakingFIS.fis');    % original FIS in the designer app

%% LOCAL FUNCTION (must stay at the end of the script file)
% Takes the steering value and returns the direction as text.
% Positive steering = right, negative = left (as defined in rules R1 and R2).
function dir = ternaryDir(val)
    if val > 2
        dir = 'Right';
    elseif val < -2
        dir = 'Left';
    else
        dir = 'Straight';
    end
end

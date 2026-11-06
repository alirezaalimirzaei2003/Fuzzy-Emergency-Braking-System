%  Tamrin-Mazad: System-e Fuzzy Sugeno Martabe-ye Aval 
%  Mozoo: Tormoz-e Ezterari va Rahyabie khodroye Khodran ba 2 Khorooji
%  Voroodiha: Fasele Jelo / Rast / Chap ( ba sensor Lidar) + Sorate feeli
%  khodro
%  Khoroojiha: Zaviye charkhesh Farman + Feshar-e Tormoz 



clear; clc; close all; 

% Sakhte  systeme fuzzy Sugeno
fis = sugfis('Name','Tormoz_Ezterari');

%% VOROODIHA 

% 1) Fasele Jelo (Metr) - Sensore jelo mashin
fis = addInput(fis,[0 10],'Name','Jelo');
% Agar mane' beine 0 ta 1.5 metr bashe -> Tasadofe hatmi (Barkhord)
fis = addMF(fis,'Jelo','trapmf',[0 0 0.5 1.5],'Name','Barkhord');
% Agar mane' beine 1 ta 5 metr bashe -> Nazdik 
fis = addMF(fis,'Jelo','trimf', [1 3 5],       'Name','Nazdik');
% Agar mane' bishtar az 4 metr bashe -> Masir baz va amn ast 
fis = addMF(fis,'Jelo','trapmf',[4 6 10 10],   'Name','Door');

% 2) Fasele Rast (Metr) - Sensore rast mashin
fis = addInput(fis,[0 5],'Name','Raast');
% Agar mane  zire 1.5 metr bashe dar samte rast -> Masir baste ast
fis = addMF(fis,'Raast','trapmf',[0 0 0.5 1.5],'Name','Baste');
% Agar mane  balaye 1 metr bashe -> Masir baz ast 
fis = addMF(fis,'Raast','trapmf',[1 2 5 5],     'Name','Baaz');

% 3) Fasele Chap (Metr) - Sensore chap mashin
fis = addInput(fis,[0 5],'Name','Chap');
% Haman manteghe samte rast baraye chap ham estefade mishavad
fis = addMF(fis,'Chap','trapmf',[0 0 0.5 1.5],'Name','Baste');
fis = addMF(fis,'Chap','trapmf',[1 2 5 5],     'Name','Baaz');

% 4) Soraate Feli (Metr bar Saniye) 
fis = addInput(fis,[0 2],'Name','Soraat');
% Soraate kam (zire 0.8) -> Kond
fis = addMF(fis,'Soraat','trapmf',[0 0 0.3 0.8],'Name','Kond');
% Soraate bala (balaye 0.6) -> Tond
fis = addMF(fis,'Soraat','trapmf',[0.6 1.2 2 2],'Name','Tond');

%% KHOROOJIHA va (moadelate khati sugeno)
% Hamantor ke midoonin Dar Sugeno martabe aval, khoroojiha adade sabet nistand, moadelee khatti
% hastand

% Tarife bazeye khoroojiha (-45 ta 45 daraje baraye farman, 0 ta 100 darsad tormoz)
fis = addOutput(fis,[-45 45],'Name','CharkheshFarmaan');
fis = addOutput(fis,[0 100], 'Name','Tormoz');

% Zarayebe moadele khatti be tartib: [Jelo, Rast, Chap, Soraat, AdadeSabet]
% Formul khorooji = (a*Jelo) + (b*Rast) + (c*Chap) + (d*Soraat) + AdadeSabet
CharkheshFarmaanParams = {
    [0  0  0  3  35];    % R1: Tasadof hatmi + Rast baz -> Pish farz 35 daraje be rast + (3 * Soraat)
    [0  0  0 -3 -35];    % R2: Tasadof hatmi + Chap baz -> Pish farz 35 daraje be chap - (3 * Soraat)
    [0  0  0  2  20];    % R3: Tasadof hatmi + Har 2 baz -> Mirim rast ba shibe kamtar
    [0  0  0  0   0];    % R4: Tasadof hatmi + Har 2 baste -> Farman 0 (Faghat tormoz)
    [-3 0  0  5  15];    % R5: Mane nazdik + Rast baz -> Formule dynamic bar asase fasele
    [3  0  0 -5 -15];    % R6: Mane nazdik + Chap baz -> Formule dynamic bar asase fasele
    [0  0  0  0   0];    % R7: Mane nazdik + Har 2 baste -> Farman 0
    [-2 0  0  3  10];    % R8: Mane nazdik + Har 2 baz -> Charkheshe narm be rast
    [0  0  0  0   0];    % R9: Masir door (Amn) -> Farman sefr (Harekate mostaghim)
};

TormozParams = {
    [0  0  0 10  80];    % R1: Tormoz shadid 80% + (10 * Soraat)
    [0  0  0 10  80];    % R2: Tormoz shadid
    [0  0  0  8  75];    % R3: Tormoz shadid
    [0  0  0  0 100];    % R4: Tormoze 100% va kamel (Taleh)
    [-2 0  0  8  30];    % R5: Tormoze narmtar chon masir baaz ast
    [-2 0  0  8  30];    % R6: Tormoze narmtar
    [-3 0  0 10  60];    % R7: Tormoze nimeshadid 
    [-1 0  0  5  25];    % R8: Tormoze khafif
    [0  0  0  2   5];    % R9: Ye nishtormoz age sorat kheyli bala bood
};

% Ezafe kardane in moadelehaye khatti be onvane tavabe ozviyate khorooji
for i = 1:9
    fis = addMF(fis,'CharkheshFarmaan','linear',CharkheshFarmaanParams{i},'Name',['CharkheshFarmaanR' num2str(i)]);
    fis = addMF(fis,'Tormoz','linear',TormozParams{i},'Name',['TormozR' num2str(i)]);
end

%% GHAVANIN 
% Format: [Jelo Rast Chap Soraat | farman Tormoz | Vazn | AND(1)]
% Adad 0 dar voroodi = "Mohem Nist" (Niyazi be barresie in sensor nist)
ruleList = [
    1  2  1  0   1  1   1  1;   % R1: Jelo(Barkhord), Rast(Baaz), Chap(Baste)
    1  1  2  0   2  2   1  1;   % R2: Jelo(Barkhord), Rast(Baste), Chap(Baaz)
    1  2  2  0   3  3   1  1;   % R3: Jelo(Barkhord), Rast(Baaz), Chap(Baaz)
    1  1  1  0   4  4   1  1;   % R4: Jelo(Barkhord), Rast(Baste), Chap(Baste)
    2  2  1  0   5  5   1  1;   % R5: Jelo(Nazdik), Rast(Baaz), Chap(Baste)
    2  1  2  0   6  6   1  1;   % R6: Jelo(Nazdik), Rast(Baste), Chap(Baaz)
    2  1  1  0   7  7   1  1;   % R7: Jelo(Nazdik), Har do baste
    2  2  2  0   8  8   1  1;   % R8: Jelo(Nazdik), Har do baaz
    3  0  0  0   9  9   1  1;   % R9: Jelo(Door) -> Baghiye sensorha 0 (mohem nistan)
];
fis = addRule(fis,ruleList);

%%  ZAKHIRE SAZI file fis

save('EmergencyBrakingFIS.mat','fis');

writeFIS(fis,'EmergencyBrakingFIS.fis');


%% Tarife Senarioha
scenarios = [
    0.3  3.0  0.5  1.5;   % Senario 1: Barkhord hatmi, rast baaz, soraat bala
    0.3  0.5  0.5  0.5;   % Senario 2: Barkhord hatmi, hameja baste (Taleh)
    3.0  3.0  0.5  1.0;   % Senario 3: Mane nazdik, rast baz, sorat motevaset
    8.0  1.0  1.0  1.8;   % Senario 4: Masir kamelan baaz, soraat bala
];
names = {'Barkhord + Masire farar rast', 'Barkhord + Mohasere kamel (Taleh)', ...
         'Mane nazdik + Rast baz', 'Masir baz va sorat bala'};
inputNames = {'Jelo (Fasele Jelo)', 'Raast (Fasele Raast)', 'Chap (Fasele Chap)', 'Soraat (Soraat)'};


% Dar in bakhsh baraye har senario yek panjere baz mishavad ta tavabe dargir neshoon dade shavand.

for k = 1:size(scenarios,1)
    
    figName = sprintf('Senario %d: %s', k, names{k});
    figure('Name', figName, 'NumberTitle', 'off', 'Position', [100+(k*20), 100+(k*20), 900, 600]);
    sgtitle(sprintf('Fuzzification dar Senario %d: %s', k, names{k}));
    
    for i = 1:4
        subplot(2, 2, i);
        plotmf(fis, 'input', i); 
        hold on;
        
       
        % In khat neshon mide ke in adad kodam tavabe ozviat ra ba che darsadi ghat mikonad
        current_val = scenarios(k, i);
        xline(current_val, 'r--', 'LineWidth', 2); 
        
        title(sprintf('%s = %.1f', inputNames{i}, current_val));
    end
end

%% Test va Mohasebeye Khorooji baraye scenario ha
fprintf('=== Nataayej-e System-e Fuzzy Sugeno ===\n\n');
for k = 1:size(scenarios,1)
    
    out = evalfis(fis, scenarios(k,:)); 
    
    fprintf('Senario %d (%s):\n', k, names{k});
    fprintf('  Voroodi -> Jelo=%.1f  Rast=%.1f  Chap=%.1f  Soraat=%.1f\n', scenarios(k,:));
    
    fprintf('  Khorooji -> Zaviye Farman = %.2f daraje (%s) | Feshar Tormoz = %.1f%%\n\n', ...
        out(1), ternaryDir(out(1)), out(2));
end

%% Tahlile Peyvasteye Khorooji
% In bakhsh baraye barresie raftare Gheire khatti system ast
Rangejelo = linspace(0,10,100)';  % Sakhte 100 noghte az fasele 0 ta 10
fixedInputs = [3.0 0.5 1.0];       % Farz mikonim rast baaz, chap baste va soraat 1 ast
farman1 = zeros(size(Rangejelo));
Tormoz2 = zeros(size(Rangejelo));

for i = 1:length(Rangejelo)
    o = evalfis(fis,[Rangejelo(i) fixedInputs]);
    farman1(i) = o(1);
    Tormoz2(i) = o(2);
end

figure('Name', 'Tahlile Peyvasteye Khorooji (Defuzzification)', 'NumberTitle', 'off', 'Position', [150, 150, 800, 600]);
subplot(2,1,1);
plot(Rangejelo, farman1, 'b-','LineWidth',2);
xlabel('Fasele Jelo (Metr)'); ylabel('Zaviye Farman (Daraje)');
title('Taghiirate Zaviye Farman nesbat be fasele mane jelo (Raast=3, Chap=0.5, Soraat=1)'); grid on;

subplot(2,1,2);
plot(Rangejelo, Tormoz2, 'r-','LineWidth',2);
xlabel('Fasele Jelo (Metr)'); ylabel('Feshar Tormoz (%)');
title('Taghiirate Feshar Tormoz nesbat be fasele mane jelo'); grid on;

%%TABE-E KOMAKI  
% In tabe adade farman ra migirad va jahat ra be soorate matni barmigardanad
function dir = ternaryDir(val)
    if val > 2
        dir = 'Be Chap';
    elseif val < -2
        dir = 'Be Rast';
    else
        dir = 'Mostaghim';
    end
end


ruleview(fis); % Baz kardane panjereye teste ghavanin
fuzzyLogicDesigner('EmergencyBrakingFIS.fis'); % Baz kardane tarrhe aselie fuzzy

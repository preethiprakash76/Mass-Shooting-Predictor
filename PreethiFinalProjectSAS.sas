TITLE "Import Mass Shooting";
proc import datafile="updated shooting.xlsx" 
out=Shooting dbms=xlsx replace;
datarow=2row;
getnames=yes;
run;
proc print data=Shooting;
run; 

data ShootingData;
set Shooting;
d_Midwest=(Region="Midwest");
d_West=(Region="West");
d_Northeast=(Region="Northeast");
d_Southeast=(Region="Southeast");
d_Southwest=(Region="Southwest");
d_Female=(U_Gender="Female");
d_Male=(U_Gender= "Male");
d_Bothgender=(U_Gender="Both");
d_White=(U_Race="White American or European American");
d_Black= (U_Race="Black American or African American");
d_Asian=(U_Race="Asian");
d_Latino= (U_Race="Latino");
d_OtherRaces=(U_Race= "Other");
d_MultipleRaces= (U_Race="Two or more races");
d_NativeAmerican= (U_Race="Native American or Alaska Native");
d_positivementalhealth=(u_mental_health="Yes");
d_negativementalhealth=(u_mental_health="No");
Run;
proc print data=ShootingData;
run;


Title"Frequency -Gender";
proc freq;
tables U_Gender;
run;

title"boxplot male Vs Fatalities";
proc sort;
by d_Male;
run;
proc boxplot;
plot Fatalities*d_Male;
run;

title" boxplot d_male VS injuried";
proc sort;
by d_Male;
run;
proc boxplot;
plot Injured*d_Male;
run;

title "boxplot totalvictims Vs males";
proc sort;
by d_Male;
run;
proc boxplot;
plot Total_victims*d_Male;
run;

title"pearson table";
proc corr;
var d_Male  d_Midwest  d_White d_Black d_Asian d_Latino d_OtherRaces d_MultipleRaces d_NativeAmerican d_positivementalhealth  d_negativementalhealth Fatalities Total_victims Injured;
run;
proc reg;
*Checking VIF;
model d_Male = d_Southeast d_White d_Black d_Asian d_Latino d_OtherRaces d_MultipleRaces d_NativeAmerican d_positivementalhealth  d_negativementalhealth Fatalities Total_victims Injured /vif tol;
run;



title "centered variables";
data centered;
set ShootingData;
Fatalities_c= 4.37500 -Fatalities;
Injured_c= 6.16250-Injured;
Total_victims_c= 10.18750-Total_victims;
run;
proc reg;
*full model;
model d_Male = d_Southeast d_White d_Black d_Asian d_Latino d_OtherRaces d_MultipleRaces d_NativeAmerican d_positivementalhealth  d_negativementalhealth Fatalities_c Total_victims_c Injured_c /vif tol;
run;


proc reg data=ShootingData;
*full model WITHOUT INJURED;
model d_Male = d_Southeast d_White d_Black d_Asian d_Latino d_OtherRaces d_MultipleRaces d_NativeAmerican d_positivementalhealth  d_negativementalhealth Fatalities Total_victims /vif tol;
run;

data InteractionShootingData;
set ShootingData;
d_Southeast_postive_Asian=(d_Southeast*d_positivementalhealth*d_Asian);
postive_Asian=(d_positivementalhealth*d_Asian);
d_Southeast_Asian=(d_Southeast*d_Asian);
postive_Fatalities=(d_positivementalhealth*Fatalities);
postive_Asian_fatalities=(d_positivementalhealth*d_Asian*fatalities);
run;
proc print data=InteractionShootingData;
run;



title"Test and tain sets";
proc surveyselect data=InteractionShootingData out=traintest_data seed=76598
samprate=0.83 outall;
run;
proc print data=traintest_data;
run;
data traintest_data;
set traintest_data;
if selected then d_NewMale=d_Male;
run;
proc print data=traintest_data;
run;

title "full model(whole)";
proc logistic data=traintest_data;
model d_NewMale(event='1')= d_Southeast d_Asian d_positivementalhealth  d_negativementalhealth Fatalities Total_victims Injured
d_Southeast_postive_Asian postive_Asian d_Southeast_Asian postive_Fatalities postive_Asian_fatalities /  rsquare corrb ;
run;

title "fullmodel with my race and region";
proc logistic data=traintest_data;
model d_NewMale(event='1')= d_Southeast d_Asian d_positivementalhealth  d_negativementalhealth Fatalities Total_victims Injured
d_Southeast_postive_Asian postive_Asian d_Southeast_Asian postive_Fatalities postive_Asian_fatalities / rsquare;
run;
proc logistic data=traintest_data;

title "model selection forward";
proc logistic data=traintest_data;
model d_NewMale(event='1')= d_Southeast d_Asian d_positivementalhealth  d_negativementalhealth Fatalities Total_victims 
d_Southeast_postive_Asian postive_Asian d_Southeast_Asian postive_Fatalities postive_Asian_fatalities /selection=forward rsquare influence iplots corrb stb;
run;

title "model selection backward";
proc logistic data=traintest_data;
model d_NewMale(event='1')= d_Southeast d_Asian d_positivementalhealth  d_negativementalhealth Fatalities Total_victims 
d_Southeast_postive_Asian postive_Asian d_Southeast_Asian postive_Fatalities postive_Asian_fatalities /selection=backward rsquare influence iplots corrb stb;
run;

*remove outlier #29;
title "Data set after removing the outlier 29";
data traintest_data;
set traintest_data;
*remove 29 observation;
if _n_=29 then delete;
run;
proc print;
run;

proc logistic data=traintest_data;
title "Data set after removing the outlier 29";
model d_NewMale(event='1')=   d_negativementalhealth d_positivementalhealth  / rsquare influence iplots corrb stb;
run;


Title "Threshold value";
proc logistic data=traintest_data;
model d_NewMale(event='1')=  d_positivementalhealth  d_negativementalhealth   /selection=forward rsquare influence iplots corrb stb;
run;
Proc Print;
Run;

proc logistic data=traintest_data;
model d_NewMale (event='1') =  d_positivementalhealth  d_negativementalhealth   / ctable pprob= (0.4 to 0.9 by 0.05);
run;

proc logistic data=traintest_data;
model d_NewMale (event='1') = d_positivementalhealth  d_negativementalhealth  ;
output out =outpred(where=(d_NewMale=.)) p=phat lower=lcl upper=ucl
predprobs=(individual);
run;
proc print;
run;

data final;
set outpred;
pred_y=0;
threshold=0.85;
if phat>threshold then pred_y=1;
run;
proc print;
run;

title"prediction";
proc freq data=final;
tables d_Male*pred_Y/norow nocol nopercent;
run;

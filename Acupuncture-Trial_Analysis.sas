/*****************************************************************************************
Clinical Trial Analysis: Acupuncture Headache Study
Author: Jay Sminchak
Date: 2025
Description:
  This program performs a complete clinical trial analysis on acupuncture vs. usual care 
  for headache outcomes. It includes data import, cleaning, descriptive analyses, 
  adjusted/unadjusted treatment effect modeling, subgroup analysis, and IPW estimation.
*****************************************************************************************/

*********************************
Importing file and 
establishing library
*********************************;
libname mt "/home/u64140125/851/Mid-term";
run;
PROC IMPORT OUT= mt.ACUP 
     DATAFILE= "/home/u64140125/851/Mid-term/copy_of_acupuncture_headache_trial.xlsx" 
     DBMS=xlsx REPLACE;
     GETNAMES=YES;
RUN;

proc format;
	value sexf 0="Male" 1="Female";
	value fmt 1="A.1" 0="B.0";
	value groupf 1="Acupuncture" 0="Usual Care";
	value migf 1="Yes" 0="No";
run;

*********************************
Creating new dataset w/ 
outcome variable (change in pk)
*********************************;
data mt.ds1;
set mt.acup;
	length outcome $12;
	if (pk1 or pk5) = . then pkfinal=.;
		else pkfinal=pk5-pk1;
	if pkfinal=. then outcome="Missing";
		else outcome="Not Missing";
	format sex sexf. group groupf. migraine migf.;
run;

/*check*/
proc print data=mt.ds1 (obs=20);
	var pk1 pk5 pkfinal outcome;
run;

/*Exporting for Table 1 Vis in R*/
proc export data=mt.ds1
	outfile="/home/u64140125/851/Mid-term/ACUPVIS.csv" 
	dbms=csv
	replace;
run;

*********************************
Descriptive Statistics 
by Treatment Group
*********************************;
proc sort data=mt.ds1;
by group;
run;

title "Categorical Summary Statistics";
proc freq data=mt.ds1;
	table sex*group/norow;
	table migraine*group/norow;
run;

title "Continuous Summary Statistics";
proc means data=mt.ds1 n mean std median qrange;
	class group;
	var age chronicity pk1 pf1 painmedspk1;
run;

/* Export summary stats (Table 2) */
ods output summary=summary_stats;
proc means data=mt.ds1 n mean std median qrange;
  class group;
  var age chronicity pk1 pf1 painmedspk1;
run;
ods output close;

proc export data=summary_stats
  outfile="/home/u64140125/851/Mid-term/results/Table2_SummaryStats.csv"
  dbms=csv replace;
run;

/*Missing outcome data only*/
title "Continuous Summary Statistics (Missing Outcome)";
proc means data=mt.ds1 n mean std median qrange;
	class group;
	var age chronicity pk1 pf1 painmedspk1;
	where pkfinal=.;
run;

title "Categorical Summary Statistics (Missing Outcome)";
proc freq data=mt.ds1;
	table sex*group/norow;
	table migraine*group/norow;
	where pkfinal=.;
run;

***********************************************
Continuous Outcome Primary
Treatment Effect Analysis (Proc GLM)
***********************************************;

/*creating Complete-Case-Analysis Dataset*/
data ds2;
	set mt.ds1;
	where outcome="Not Missing";
run;

/*****Adjusted Linear Regression*****/
ods output parameterestimates=regression_results;
Title "Linear Regression Modeling pkfinal by Treatment Group";
proc glm data=ds2;
	class migraine (ref="No") group;
	model pkfinal=group age migraine pk1/solution clparm;
run;
ods output close;
/*****Without adjusting for pk1*****/
title2 "Without Adjusting for pk1";
proc glm data=ds2;
	class migraine (ref="No") group;
	model pkfinal=group age migraine/solution clparm;
run;

/*****Unadjusted model*****/
title2 "Unadjusted Model";
proc glm data=ds2;
	class group;
	model pkfinal=group/solution clparm;
run;
title;

/* Export regression results (Table 3) */
proc export data=regression_results
  outfile="/home/u64140125/851/Mid-term/results/Table3_RegressionResults.csv"
  dbms=csv replace;
run;

***********************************************
Effect Modification by Migraine Status Analysis
***********************************************;
proc sort data=ds2;
by migraine descending group;
run;

/*Graphical Display of Interaction*/
ods exclude all;
ods output conflimits=ci_results;
proc ttest data=ds2 order=data;
	class group;
	var pkfinal;
	by migraine;
run;
ods exclude none;
data diff_ci;
    set ci_results;
    where Method = "Pooled";
    mean_diff = mean;
    lower = LowerCLMean;
    upper = upperCLMean;

    keep Migraine mean_diff lower upper;
run;

/* Export Figure 1: Interaction Plot */
ods listing gpath="/home/u64140125/851/Mid-term/results";
ods graphics / imagename="Figure1_InteractionPlot" imagefmt=png;

proc sgplot data=diff_ci;
    scatter x=migraine y=mean_diff /
        yerrorlower=lower yerrorupper=upper
        markerattrs=(symbol=CircleFilled size=12 color=darkblue)
        errorbarattrs=(thickness=2 color=darkblue);
    refline 0 / axis=y lineattrs=(pattern=shortdash color=gray thickness=2);
    xaxis label="Migraine at Baseline" type=discrete valueattrs=(size=12) labelattrs=(size=12);
    yaxis label="Mean Difference (Acupuncture vs Control)" valueattrs=(size=12) labelattrs=(size=12);
    title "Crude Mean Difference in Change in Headache Score by Migraine Status";
    title2 "With 95% Confidence Intervals";
run;

ods listing close;

/*Subgroup Analysis*/
title "Subgroup Analysis Stratified by Baseline Migraine Status";
proc glm data=ds2;
class group;
model pkfinal=group age pk1/solution clparm;
by migraine;
run;

/*test for interaction*/
title "Test of Interaction between Treatment Group and Baseline Migraine Status";
proc glm data=ds2;
class migraine (ref="No") group;
model pkfinal=group|Migraine age pk1/solution clparm;
run;
title;

***********************************************
Per-Protocol Effect Estimation via IPW
***********************************************;   
/*IPW Analysis*/
proc logistic data=mt.ds1;
class sex (ref="Male")/param=reference;
model outcome (event="Not Missing")= sex age chronicity pf1 pk1 painmedspk1;
output out=prob p=prob_NM;
run;quit;

data prob1;
set prob;
if outcome="Not Missing" then wt=1/prob_NM;
else wt=.;
run;

title "Per-Protocol Effect Estimation via IPW";
proc genmod data=prob1;
class sex id group;
model pkfinal = group sex age chronicity pf1 pk1 painmedspk1;
repeated subject = id / type=ind;
run;

***********************************************
Binary Outcome Secondary Analysis 
(Pain Med Decrease) + Interaction by Sex
***********************************************;
proc format;
value fmt 1='A.1'
	      0='B.0';
run;

/*Creating dataset w/ proper vriables*/
data binary;
set mt.ds1;
if painmedspk5=. then PM_Decrease=.;
else if (painmedspk5-painmedspk1)<0 then PM_Decrease=1;
else PM_Decrease=0;
format PM_Decrease fmt.;
run;
proc print data=binary (obs=20);
var painmedspk5 painmedspk1 pm_decrease;
run;

/*complete-case data*/
data binary_complete;
set binary;
where pm_decrease NE .;
run;

*********************************
Descriptive Statistics 
by Treatment Group
*********************************;
/*Overall*/
title "Descriptive Statistics by Treatment Group";
proc freq data=binary_complete order=formatted;
table group*pm_decrease/ nocol
riskdiff (column=1 CL=wald CL=newcombe(correct) norisks)
relrisk (column=1 cl=wald)
oddsratio(cl=wald);
run;

/*Stratified by sex*/
ods output oddsratiocls=oddsratio_results;
title "Descriptive Statistics by Treatment Group Stratified by Sex";
proc freq data=binary_complete order=formatted;
table sex*group*pm_decrease/ nocol
riskdiff (column=1 CL=wald CL=newcombe(correct) norisks)
relrisk (column=1 cl=wald)
oddsratio(cl=wald);
run;
ods output close;
proc print data=oddsratio_results;
run;

/*test for interaction via Breslow-Day test*/
title "Breslow-Day Test for Interaction between Sex and Treatment Group";
proc freq data=binary_complete order=formatted;
table sex*group*pm_decrease/ chisq cmh;
run;

/*overall Odds Ratio*/
title "Test for Odds Ratio for the Binary Outcome";
proc freq data=binary_complete order=formatted;
tables group*pm_decrease/chisq oddsratio(cl=wald);
run;

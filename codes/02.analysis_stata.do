********************************************************************************
*** Previous preparation - calculation of variables ***
********************************************************************************
* Percentage of sites with bleeding on probing
egen bop_count = anycount(bop_d_17-bop_l_37), values(2/1000)
egen bop_sites_total = rownonmiss(bop_d_17-bop_l_37)
gen pct_bop = (bop_count / bop_sites_total) * 100
label variable pct_bop "Percentage of sites with BOP (%)"

* Total number of probed sites (denominator for all PD percentages)
egen pd_sites_total = rownonmiss(pd_d_17-pd_l_37)

* Percentage of sites with PD = 4 mm
gen pd4_count = 0
foreach var of varlist pd_d_17-pd_l_37 {
    replace pd4_count = pd4_count + (`var' == 4) if !missing(`var')
}
gen pct_pd4 = (pd4_count / pd_sites_total) * 100
replace pct_pd4 = . if pd_sites_total == 0
label variable pct_pd4 "Percentage of sites with PD = 4 mm"

* Percentage of sites with PD = 5-6 mm
gen pd5_6_count = 0
foreach var of varlist pd_d_17-pd_l_37 {
    replace pd5_6_count = pd5_6_count + inlist(`var', 5, 6) if !missing(`var')
}
gen pct_pd5_6 = (pd5_6_count / pd_sites_total) * 100
replace pct_pd5_6 = . if pd_sites_total == 0
label variable pct_pd5_6 "Percentage of sites with PD = 5-6 mm"

* Percentage of sites with PD >= 7 mm
gen pd7plus_count = 0
foreach var of varlist pd_d_17-pd_l_37 {
    replace pd7plus_count = pd7plus_count + (`var' >= 7) if !missing(`var')
}
gen pct_pd7plus = (pd7plus_count / pd_sites_total) * 100
replace pct_pd7plus = . if pd_sites_total == 0
label variable pct_pd7plus "Percentage of sites with PD >= 7 mm"

* Periodontitis stage — categorized
generate perio_stage_cat = .
replace perio_stage_cat = 0 if perio_stage == 0
replace perio_stage_cat = 1 if perio_stage == 1 | perio_stage == 2
replace perio_stage_cat = 2 if perio_stage == 3 | perio_stage == 4
label define perio_stage_cat_lbl 0 "Health/gingivitis" 1 "Stage I/II" 2 "Stage III/IV"
label values perio_stage_cat perio_stage_cat_lbl
label variable perio_stage_cat "Periodontitis stage (categorized)"


********************************************************************************
*** Table 1 — Sociodemographic characteristics (matched case-control pairs) ***
********************************************************************************
capture log close
log using "C:\your\path\here\Table_1.log", replace

* Descriptive statistics
* Age and sex: matching variables — descriptives only (p = 1.000 by design)
tabstat age, by(case_status) statistics(mean sd n)
tab sex case_status, col
tab education case_status, col
tab income case_status, col
tab smoking case_status, col
tab alcohol case_status, col
tab diabetes case_status, col

* Paired tests (reshape to one row per matched pair)
preserve
keep match_id case_status education income smoking alcohol diabetes
destring match_id, replace
reshape wide education income smoking alcohol diabetes, i(match_id) j(case_status)

* Binary variables: McNemar exact test
symmetry education0 education1, exact
symmetry smoking0 smoking1, exact
symmetry alcohol0 alcohol1, exact
symmetry diabetes0 diabetes1, exact

* Polytomous variable: Stuart-Maxwell test
symmetry income0 income1, exact

restore

log close



********************************************************************************
*** Table 2 — Periodontal characteristics (matched case-control pairs) ***
********************************************************************************
capture log close
log using "C:\your\path\here\Table_2.log", replace

*Derived variables (if not already created)
capture drop mean_pd mean_cal
egen mean_pd = rowmean(pd_d_17-pd_l_37)
label variable mean_pd "Mean probing depth (mm)"
egen mean_cal = rowmean(cal_d_17-cal_l_37)
label variable mean_cal "Mean clinical attachment level (mm)"

*Descriptive statistics
tab periodontitis case_status, col
tab perio_stage_cat case_status, col
tabstat mean_cal, by(case_status) statistics(mean sd n)
tabstat mean_pd, by(case_status) statistics(mean sd n)
tabstat pct_bop, by(case_status) statistics(mean sd n)
tabstat plaque_pct, by(case_status) statistics(mean sd n)
tabstat pct_pd4, by(case_status) statistics(mean sd n)
tabstat pct_pd5_6, by(case_status) statistics(mean sd n)
tabstat pct_pd7plus, by(case_status) statistics(mean sd n)

*Paired tests (reshape to one row per matched pair)
preserve
keep match_id case_status periodontitis perio_stage_cat mean_pd mean_cal plaque_pct pct_bop pct_pd4 pct_pd5_6 pct_pd7plus
destring match_id, replace
reshape wide periodontitis perio_stage_cat mean_pd mean_cal plaque_pct pct_bop pct_pd4 pct_pd5_6 pct_pd7plus, i(match_id) j(case_status)

*Categorical — paired tests
symmetry periodontitis0 periodontitis1, exact
symmetry perio_stage_cat0 perio_stage_cat1, exact

*Continuous — normality of paired differences
gen diff_mean_pd = mean_pd1 - mean_pd0
gen diff_mean_cal = mean_cal1 - mean_cal0
gen diff_plaque_pct = plaque_pct1 - plaque_pct0
gen diff_pct_bop = pct_bop1 - pct_bop0
gen diff_pct_pd4 = pct_pd41 - pct_pd40
gen diff_pct_pd5_6 = pct_pd5_61 - pct_pd5_60
gen diff_pct_pd7plus = pct_pd7plus1 - pct_pd7plus0

swilk diff_mean_pd diff_mean_cal diff_plaque_pct diff_pct_bop diff_pct_pd4 diff_pct_pd5_6 diff_pct_pd7plus

*Paired tests for continuous variables
*If diff is normal (swilk p > 0.05) → paired t-test: ttest diff_VARNAME == 0
*If diff is non-normal (swilk p <= 0.05) → Wilcoxon signed-rank:
signrank mean_cal1 = mean_cal0
signrank mean_pd1 = mean_pd0
signrank plaque_pct1 = plaque_pct0
signrank pct_bop1 = pct_bop0
signrank pct_pd41 = pct_pd40
signrank pct_pd5_61 = pct_pd5_60
signrank pct_pd7plus1 = pct_pd7plus0
restore

log close



********************************************************************************
*** Table 3 — Conditional logistic regression (matched case-control pairs) ***
********************************************************************************
capture log close
log using "C:\your\path\here\Table_3.log", replace

*Crude ORs
clogit case_status c.mean_pd, group(match_id) or
clogit case_status c.mean_cal, group(match_id) or
clogit case_status c.pct_bop, group(match_id) or
clogit case_status c.pct_pd4, group(match_id) or
clogit case_status i.education, group(match_id) or
clogit case_status i.income, group(match_id) or
clogit case_status i.smoking, group(match_id) or
clogit case_status i.alcohol, group(match_id) or
clogit case_status i.diabetes, group(match_id) or

*------------------------------------------------------------------------------*
* MODEL 1 - MEAN PPD
* Interaction tests — Model 1 (mean PD)
clogit case_status c.mean_pd##i.smoking i.education i.income i.alcohol i.diabetes, group(match_id) or
testparm c.mean_pd#i.smoking

clogit case_status c.mean_pd##i.diabetes i.education i.income i.smoking i.alcohol, group(match_id) or
testparm c.mean_pd#i.diabetes

clogit case_status c.mean_pd##i.alcohol i.education i.income i.smoking i.diabetes, group(match_id) or
testparm c.mean_pd#i.alcohol

clogit case_status c.mean_pd##i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or
testparm c.mean_pd#i.education

clogit case_status c.mean_pd##i.income i.education i.smoking i.alcohol i.diabetes, group(match_id) or
testparm c.mean_pd#i.income

*Testing linearity with Box-Tidwell
gen ln_mean_pd = ln(mean_pd)
gen pd_x_lnpd = mean_pd * ln_mean_pd
clogit case_status c.mean_pd c.pd_x_lnpd i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or
test pd_x_lnpd


*Final model - MODEL 1
clogit case_status c.mean_pd i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or

* Log-likelihood and pseudo R²
display "Log-likelihood (full model): " e(ll)
display "Log-likelihood (null model): " e(ll_0)
display "McFadden pseudo R²: " 1 - (e(ll)/e(ll_0))

* Model discrimination (AUC)
predict p_hat_m1, pu0
roctab case_status p_hat_m1
roctab case_status p_hat_m1, graph plotopts(lcolor(navy) lwidth(medthick) mcolor(navy) msymbol(O)) rlopts(lcolor(red)) name(graph_1, replace)
cd "C:\Users\kvufm\OneDrive\Artigos em produção\Artigo - Artrite - amanda\Helena - Artrite"
graph export "graph_1.png", name(graph_1) width(3000) replace

* Forest plot
coefplot, eform drop(_cons) horizontal xscale(log range(0.4 2.5)) xline(1, lcolor(red) lwidth(thin)) xlabel(0.5 0.75 1 1.5 2.5 5, labsize(small) angle(0)) ciopts(recast(rcap) lwidth(medthin) lcolor(gs6)) msymbol(square) msize(small) mcolor(navy) headings(1.education = "{bf:Education}" 1.income = "{bf:Household income}" 1.smoking = "{bf:Smoking}" 1.alcohol = "{bf:Alcohol}" 1.diabetes = "{bf:Diabetes}", labsize(small)) ylabel(, labsize(small)) legend(off) xtitle("Odds Ratio (95% CI)", size(small)) graphregion(color(white)) plotregion(color(white)) name(graph_2, replace)
cd "C:\Users\kvufm\OneDrive\Artigos em produção\Artigo - Artrite - amanda\Helena - Artrite"
graph export "graph_2.png", name(graph_2) width(3000) replace

*VIF test
regress case_status c.mean_pd i.education i.income i.smoking i.alcohol i.diabetes
estat vif


*------------------------------------------------------------------------------*
* MODEL 2 - PERCENTAGE OF BOP
*Testing linearity with Box-Tidwell
gen ln_pct_bop = ln(pct_bop)
gen bop_x_lnbop = pct_bop * ln_pct_bop
clogit case_status c.pct_bop c.bop_x_lnbop i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or
test bop_x_lnbop

* Interaction tests — MODEL 2
clogit case_status c.pct_bop##i.smoking i.education i.income i.alcohol i.diabetes, group(match_id) or
testparm c.pct_bop#i.smoking

clogit case_status c.pct_bop##i.diabetes i.education i.income i.smoking i.alcohol, group(match_id) or
testparm c.pct_bop#i.diabetes

clogit case_status c.pct_bop##i.alcohol i.education i.income i.smoking i.diabetes, group(match_id) or
testparm c.pct_bop#i.alcohol

clogit case_status c.pct_bop##i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or
testparm c.pct_bop#i.education

clogit case_status c.pct_bop##i.income i.education i.smoking i.alcohol i.diabetes, group(match_id) or
testparm c.pct_bop#i.income

*Final model - MODEL 2
clogit case_status c.pct_bop i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or

display "Log-likelihood (full model): " e(ll)
display "Log-likelihood (null model): " e(ll_0)
display "McFadden pseudo R²: " 1 - (e(ll)/e(ll_0))

capture drop p_hat_m3
predict p_hat_m3, pu0
roctab case_status p_hat_m3
roctab case_status p_hat_m3, graph plotopts(lcolor(navy) lwidth(medthick) mcolor(navy) msymbol(O)) rlopts(lcolor(red)) name(graph_3, replace)
cd "C:\your\path\here\"
graph export "graph_3.png", name(graph_3) width(3000) replace


coefplot, eform drop(_cons) horizontal xscale(log range(0.4 2.5)) xline(1, lcolor(red) lwidth(thin)) xlabel(0.5 0.75 1 1.5 2.5 5, labsize(small) angle(0)) ciopts(recast(rcap) lwidth(medthin) lcolor(gs6)) msymbol(square) msize(small) mcolor(navy) headings(1.education = "{bf:Education}" 1.income = "{bf:Household income}" 1.smoking = "{bf:Smoking}" 1.alcohol = "{bf:Alcohol}" 1.diabetes = "{bf:Diabetes}", labsize(small)) ylabel(, labsize(small)) legend(off) xtitle("Odds Ratio (95% CI)", size(small)) graphregion(color(white)) plotregion(color(white)) name(graph_4, replace)
cd "C:\your\path\here\"
graph export "graph_4.png", name(graph_4) width(3000) replace

*VIF test
regress case_status c.pct_bop i.education i.income i.smoking i.alcohol i.diabetes
estat vif

*------------------------------------------------------------------------------*
*MODEL 3 - MEAN CAL
*Testing linearity with Box-Tidwell
gen ln_mean_cal = ln(mean_cal)
gen cal_x_lncal = mean_cal * ln_mean_cal
clogit case_status c.mean_cal c.cal_x_lncal i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or
test cal_x_lncal

*Testing quadratic term
clogit case_status c.mean_cal##c.mean_cal i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or
testparm c.mean_cal#c.mean_cal

*Categorizing CAL by tertiles
xtile mean_cal_cat = mean_cal, nq(3)
label define cal3 1 "Tertile 1" 2 "Tertile 2" 3 "Tertile 3"
label values mean_cal_cat cal3

tab mean_cal_cat, summarize(mean_cal)
bysort mean_cal_cat: summarize mean_cal, detail

clogit case_status i.mean_cal_cat, group(match_id) or

* Interaction tests — Model 3 (mean CAL tertiles)
clogit case_status i.mean_cal_cat##i.smoking i.education i.income i.alcohol i.diabetes, group(match_id) or
testparm i.mean_cal_cat#i.smoking

clogit case_status i.mean_cal_cat##i.diabetes i.education i.income i.smoking i.alcohol, group(match_id) or
testparm i.mean_cal_cat#i.diabetes

clogit case_status i.mean_cal_cat##i.alcohol i.education i.income i.smoking i.diabetes, group(match_id) or
testparm i.mean_cal_cat#i.alcohol

clogit case_status i.mean_cal_cat##i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or
testparm i.mean_cal_cat#i.education

clogit case_status i.mean_cal_cat##i.income i.education i.smoking i.alcohol i.diabetes, group(match_id) or
testparm i.mean_cal_cat#i.income

*Final model - MODEL 3
clogit case_status i.mean_cal_cat i.education i.income i.smoking i.alcohol i.diabetes, group(match_id) or

display "Log-likelihood (full model): " e(ll)
display "Log-likelihood (null model): " e(ll_0)
display "McFadden pseudo R²: " 1 - (e(ll)/e(ll_0))

capture drop p_hat_m2
predict p_hat_m2, pu0
roctab case_status p_hat_m2
roctab case_status p_hat_m2, graph plotopts(lcolor(navy) lwidth(medthick) mcolor(navy) msymbol(O)) rlopts(lcolor(red)) name(graph_5, replace)
cd "C:\your\path\here\"
graph export "graph_5.png", name(graph_5) width(3000) replace

coefplot, eform drop(_cons) horizontal xscale(log range(0.4 2.5)) xline(1, lcolor(red) lwidth(thin)) xlabel(0.5 0.75 1 1.5 2.5 5, labsize(small) angle(0)) ciopts(recast(rcap) lwidth(medthin) lcolor(gs6)) msymbol(square) msize(small) mcolor(navy) headings(2.mean_cal_cat = "{bf:Mean CAL}" 1.education = "{bf:Education}" 1.income = "{bf:Household income}" 1.smoking = "{bf:Smoking}" 1.alcohol = "{bf:Alcohol}" 1.diabetes = "{bf:Diabetes}", labsize(small)) ylabel(, labsize(small)) legend(off) xtitle("Odds Ratio (95% CI)", size(small)) graphregion(color(white)) plotregion(color(white)) name(graph_6, replace)

cd "C:\your\path\here\"
graph export "graph_6.png", name(graph_6) width(3000) replace

*VIF test
regress case_status i.mean_cal_cat i.education i.income i.smoking i.alcohol i.diabetes
estat vif

log close



********************************************************************************
*** Figures ***
******************************************************************************** 
graph combine graph_2 graph_4 graph_6, rows(3) cols(1) xsize(5) ysize(8) iscale(0.7) name(figure_2, replace)
cd "C:\your\path\here\"
graph export "figure_2.png", name(figure_2) width(3000) replace

graph combine graph_1 graph_3 graph_5, rows(3) cols(1) xsize(5) ysize(8) iscale(0.7) name(figure_3, replace)
cd "C:\your\path\here\"
graph export "figure_3.png", name(figure_3) width(3000) replace





clear all 
set more off
set maxvar 10000


*** Working Folder Path ***
global path_in "../rdta/Afghanistan DHS 2015-16" 
global path_out "cdta"
global path_ado "ado"

		
********************************************************************************
*** AFGHANISTAN  DHS 2015-16 ***
********************************************************************************


********************************************************************************
*** Step 1: Data preparation 
*** Selecting variables from KR, BR, IR, & MR recode & merging with PR recode 
********************************************************************************

	/*Anthropometric data was not collected as part of the 
	Afghanistan DHS 2015-16 dataset. */


********************************************************************************
*** Step 1.1 PR - CHILDREN's RECODE (under 5)
********************************************************************************
	
	//No anthropometric data for children


********************************************************************************
*** Step 1.2  BR - BIRTH RECODE 
*** (All females 15-49 years who ever gave birth)  
********************************************************************************


use "$path_in/AFBR70FL.DTA", clear

*** Generate individual unique key variable required for data merging
*** v001=cluster number;  
*** v002=household number; 
*** v003=respondent's line number
gen double ind_id = v001*1000000 + v002*100 + v003 
format ind_id %20.0g
label var ind_id "Individual ID"


desc b3 b7	
gen date_death = b3 + b7
	//Date of death = date of birth (b3) + age at death (b7)
gen mdead_survey = v008 - date_death
	//Months dead from survey = Date of interview (v008) - date of death
gen ydead_survey = mdead_survey/12
	//Years dead from survey

	
gen age_death = b7	
label var age_death "Age at death in months"
tab age_death, miss

	
	
codebook b5, tab (10)	
gen child_died = 1 if b5==0
	//1=child dead; 0=child alive
replace child_died = 0 if b5==1
replace child_died = . if b5==.
label define lab_died 1 "child has died" 0 "child is alive"
label values child_died lab_died
tab b5 child_died, miss
	

	/*NOTE: For each woman, sum the number of children who died and compare to 
	the number of sons/daughters whom they reported have died */
bysort ind_id: egen tot_child_died = sum(child_died) 
egen tot_child_died_2 = rsum(v206 v207)
	//v206: sons who have died; v207: daughters who have died
compare tot_child_died tot_child_died_2
	//Afghanistan DHS 2015-16: these figures are identical
	
		
	//Identify child under 18 mortality in the last 5 years
gen child18_died = child_died 
replace child18_died=0 if age_death>=216 & age_death<.
label values child18_died lab_died
tab child18_died, miss	
			
bysort ind_id: egen tot_child18_died_5y=sum(child18_died) if ydead_survey<=5
	/*Total number of children under 18 who died in the past 5 years 
	prior to the interview date */	
	
replace tot_child18_died_5y=0 if tot_child18_died_5y==. & tot_child_died>=0 & tot_child_died<.
	/*All children who are alive or who died longer than 5 years from the 
	interview date are replaced as '0'*/
	
replace tot_child18_died_5y=. if child18_died==1 & ydead_survey==.
	//Replace as '.' if there is no information on when the child died  

tab tot_child_died tot_child18_died_5y, miss

bysort ind_id: egen childu18_died_per_wom_5y = max(tot_child18_died_5y)
lab var childu18_died_per_wom_5y "Total child under 18 death for each women in the last 5 years (birth recode)"
	

	//Keep one observation per women
bysort ind_id: gen id=1 if _n==1
keep if id==1
drop id
duplicates report ind_id 

gen women_BR = 1 
	//Identification variable for observations in BR recode

	
	//Retain relevant variables
keep ind_id women_BR childu18_died_per_wom_5y 
order ind_id women_BR childu18_died_per_wom_5y
sort ind_id
save "$path_out/AFG15-16_BR.dta", replace	


********************************************************************************
*** Step 1.3  IR - WOMEN's RECODE  
*** (All eligible females 15-49 years in the household)
********************************************************************************

use "$path_in/AFIR70FL.DTA", clear


*** Generate individual unique key variable required for data merging
*** v001=cluster number;  
*** v002=household number; 
*** v003=respondent's line number
gen double ind_id = v001*1000000 + v002*100 + v003 
format ind_id %20.0g
label var ind_id "Individual ID"

duplicates report ind_id
	//No duplicates	

gen women_IR=1 
	//Identification variable for observations in IR recode


keep ind_id women_IR v003 v005 v012 v201 v206 v207 
order ind_id women_IR v003 v005 v012 v201 v206 v207 
sort ind_id
save "$path_out/AFG15-16_IR.dta", replace


********************************************************************************
*** Step 1.4  IR - WOMEN'S RECODE  
*** (Girls 15-19 years in the household)
********************************************************************************
	
	//No anthropometric data


	
********************************************************************************
*** Step 1.5  MR - MEN'S RECODE  
***(All eligible man: 15-49 years in the household) 
********************************************************************************

use "$path_in/AFMR70FL.DTA", clear 


*** Generate individual unique key variable required for data merging
	*** mv001=cluster number; 
	*** mv002=household number;
	*** mv003=respondent's line number
gen double ind_id = mv001*1000000 + mv002*100 + mv003 	
format ind_id %20.0g
label var ind_id "Individual ID"

duplicates report ind_id
	//No duplicates	

gen men_MR=1 	
	//Identification variable for observations in MR recode


keep ind_id men_MR mv003 mv005 mv012 mv201 mv206 mv207 
order ind_id men_MR mv003 mv005 mv012 mv201 mv206 mv207
sort ind_id
save "$path_out/AFG15-16_MR.dta", replace


********************************************************************************
*** Step 1.6  PR - INDIVIDUAL RECODE  
*** (Boys 15-19 years in the household)
********************************************************************************

	//No anthropometric data

********************************************************************************
*** Step 1.7  PR - HOUSEHOLD MEMBER'S RECODE 
********************************************************************************

use "$path_in/AFPR70FL.DTA", clear

*** Generate a household unique key variable at the household level using: 
	***hv001=cluster number 
	***hv002=household number
gen double hh_id = hv001*10000 + hv002 
format hh_id %20.0g
label var hh_id "Household ID"
codebook hh_id  


*** Generate individual unique key variable required for data merging using:
	*** hv001=cluster number; 
	*** hv002=household number; 
	*** hvidx=respondent's line number.
gen double ind_id = hv001*1000000 + hv002*100 + hvidx 
format ind_id %20.0g
label var ind_id "Individual ID"
codebook ind_id


sort hh_id ind_id


********************************************************************************
*** Step 1.8 DATA MERGING 
******************************************************************************** 
 
 
*** Merging BR Recode 
*****************************************
merge 1:1 ind_id using "$path_out/AFG15-16_BR.dta"
drop _merge
erase "$path_out/AFG15-16_BR.dta"


*** Merging IR Recode 
*****************************************
merge 1:1 ind_id using "$path_out/AFG15-16_IR.dta"  
drop _merge
erase "$path_out/AFG15-16_IR.dta"


*** Merging MR Recode
*****************************************
merge 1:1 ind_id using "$path_out/AFG15-16_MR.dta"
drop _merge
erase "$path_out/AFG15-16_MR.dta"


sort ind_id


********************************************************************************
*** Step 1.9 KEEPING ONLY DE JURE HOUSEHOLD MEMBERS ***
********************************************************************************

//Permanent (de jure) household members 
clonevar resident = hv102 
codebook resident, tab (10) 
label var resident "Permanent (de jure) household member"

drop if resident!=1 
tab resident, miss
	/*Afghanistan DHS 2015-16: 1,942 (0.95%) individuals who 
	were non-usual residents were dropped from the sample.*/

	
********************************************************************************
*** Step 1.10 SUBSAMPLE VARIABLE ***
********************************************************************************

	/*Afghanistan DHS 2015-16: Anthropometric data was not collected 
	as part of the survey. As such there was no subsample selection.*/

gen subsample=.
label var subsample "Households selected as part of nutrition subsample" 
	
	
********************************************************************************
*** Step 1.11 CONTROL VARIABLES
********************************************************************************


*** No Eligible Women 15-49 years
*****************************************
gen	fem_eligible = (hv117==1)
bysort	hh_id: egen hh_n_fem_eligible = sum(fem_eligible) 	
	//Number of eligible women for interview in the hh
gen	no_fem_eligible = (hh_n_fem_eligible==0) 									
	//Takes value 1 if the household had no eligible females for an interview
lab var no_fem_eligible "Household has no eligible women"
tab no_fem_eligible, miss


*** No Eligible Men 15-49 years
*****************************************
gen	male_eligible = (hv118==1)
bysort	hh_id: egen hh_n_male_eligible = sum(male_eligible)  
	//Number of eligible men for interview in the hh
gen	no_male_eligible = (hh_n_male_eligible==0) 	
	//Takes value 1 if the household had no eligible males for an interview
lab var no_male_eligible "Household has no eligible man"
tab no_male_eligible, miss


*** No Eligible Children 0-5 years
*****************************************
gen	child_eligible = .  
gen	no_child_eligible = .
lab var no_child_eligible "Household has no children eligible"


*** No Eligible Women and Men 
***********************************************
gen	no_adults_eligible = (no_fem_eligible==1 & no_male_eligible==1) 
	//Takes value 1 if the household had no eligible men & women for an interview
lab var no_adults_eligible "Household has no eligible women or men"
tab no_adults_eligible, miss 


*** No Eligible Children and Women  
***********************************************
gen	no_child_fem_eligible = (no_child_eligible==1 & no_fem_eligible==1)
lab var no_child_fem_eligible "Household has no children or women eligible"
tab no_child_fem_eligible, miss 


*** No Eligible Women, Men or Children 
***********************************************
gen no_eligibles = (no_fem_eligible==1 & no_male_eligible==1 & no_child_eligible==1)
lab var no_eligibles "Household has no eligible women, men, or children"
tab no_eligibles, miss


sort hh_id ind_id


********************************************************************************
*** Step 1.12 RENAMING DEMOGRAPHIC VARIABLES ***
********************************************************************************

//Sample weight
desc hv005
clonevar weight = hv005
replace weight = weight/1000000 
label var weight "Sample weight"


//Area: urban or rural	
desc hv025
codebook hv025, tab (5)		
clonevar area = hv025  
replace area=0 if area==2  
label define lab_area 1 "urban" 0 "rural"
label values area lab_area
label var area "Area: urban-rural"


//Relationship to the head of household 
clonevar relationship = hv101 
codebook relationship, tab (20)
recode relationship (1=1)(2=2)(3=3)(11=3)(4/10=4)(12=5)(98=.)
label define lab_rel 1"head" 2"spouse" 3"child" 4"extended family" 5"not related" 
label values relationship lab_rel
label var relationship "Relationship to the head of household"
tab hv101 relationship, miss


//Sex of household member	
codebook hv104
clonevar sex = hv104 
label var sex "Sex of household member"


//Household headship
bys	hh_id: egen missing_hhead = min(relationship)
tab missing_hhead,m 
gen household_head=.
replace household_head=1 if relationship==1 & sex==1 
replace household_head=2 if relationship==1 & sex==2
bysort hh_id: egen headship = sum(household_head)
replace headship = 1 if (missing_hhead==2 & sex==1)
replace headship = 2 if (missing_hhead==2 & sex==2)
replace headship = . if missing_hhead>2
label define head 1"male-headed" 2"female-headed"
label values headship head
label var headship "Household headship"
tab headship, miss


//Age of household member
codebook hv105, tab (999)
clonevar age = hv105  
replace age = . if age>=98
label var age "Age of household member"


//Age group 
recode age (0/4 = 1 "0-4")(5/9 = 2 "5-9")(10/14 = 3 "10-14") ///
		   (15/17 = 4 "15-17")(18/59 = 5 "18-59")(60/max=6 "60+"), gen(agec7)
lab var agec7 "age groups (7 groups)"	
	   
recode age (0/9 = 1 "0-9") (10/17 = 2 "10-17")(18/59 = 3 "18-59") ///
		   (60/max=4 "60+"), gen(agec4)
lab var agec4 "age groups (4 groups)"

recode age (0/17 = 1 "0-17") (18/max = 2 "18+"), gen(agec2)		 		   
lab var agec2 "age groups (2 groups)"


//Marital status of household member
clonevar marital = hv115 
codebook marital, tab (10)
recode marital (0=1)(1=2)(8=.)
label define lab_mar 1"never married" 2"currently married" 3"widowed" ///
4"divorced" 5"not living together"
label values marital lab_mar	
label var marital "Marital status of household member"
tab hv115 marital, miss


//Total number of de jure hh members in the household
gen member = 1
bysort hh_id: egen hhsize = sum(member)
label var hhsize "Household size"
tab hhsize, miss
drop member



//Subnational region
	/*NOTE: The sample of Afghanistan DHS 2015-16 was intended to allow 
	estimates of key indicators at the national level, in urban and rural areas, 
	and for each of the 34 provinces of Afghanistan (p.1).*/ 	
clonevar region = hv024
lab var region "Region for subnational decomposition"
label define lab_reg ///
1  "Kabul" ///
2  "Kapisa" ///
3  "Parwan" ///
4  "Wardak" ///
5  "Logar" ///
6  "Nangarhar" ///
7  "Laghman" ///
8  "Panjsher" ///
9  "Baghlan" ///
10 "Bamyan" ///
11 "Ghazni" ///
12 "Paktika" ///
13 "Paktya" ///
14 "Khost" ///
15 "Kunarha" ///
16 "Nooristan" ///
17 "Badakhshan" ///
18 "Takhar" ///
19 "Kunduz" ///
20 "Samangan" ///
21 "Balkh" ///
22 "Sar-e-Pul" ///
23 "Ghor" ///
24 "Daykundi" ///
25 "Urozgan" ///
26 "Zabul" ///
27 "Kandahar" ///
28 "Jawzjan" ///
29 "Faryab" ///
30 "Helmand" ///
31 "Badghis" ///
32 "Herat" ///
33 "Farah" ///
34 "Nimroz"
label values region lab_reg
codebook region, tab (99)


	/*Harmonised over time: Afghanistan DHS 2015-16 is representative for 
	the 34 provinces. The provinces are regoruped to match the 8 regions 
	in the earlier survey. The classification follows the grouping listed
	in the survey report (p.6).*/
	
recode hv024 (1/5 8=1 "Central")     (10 24=2 "Central Highlands") ///
             (6 7 15 16=3 "East")    (20/22 28 29=4 "North")      ///
			 (9 17/19=5 "North East")(25/27 30 34=6 "South") ///
			 (11/14=7 "South East")  (23 31/33=8 "West"), gen(region_c)
lab var region_c "Region for subnational decomposition"
codebook region_c, tab (99)


********************************************************************************
***  Step 2 Data preparation  ***
***  Standardization of the 10 Global MPI indicators 
***  Identification of non-deprived & deprived individuals  
********************************************************************************


********************************************************************************
*** Step 2.1 Years of Schooling ***
********************************************************************************

codebook hv108, tab(30)
clonevar  eduyears = hv108   
	//Total number of years of education
replace eduyears = . if eduyears>30
	//Recode any unreasonable years of highest education as missing value
replace eduyears = . if eduyears>=age & age>0
	/*The variable "eduyears" was replaced with a '.' if total years of 
	education was more than individual's age */
replace eduyears = 0 if age < 10 
	/*The variable "eduyears" was replaced with a '0' given that the criteria 
	for this indicator is household member aged 10 years or older */

	
	/*A control variable is created on whether there is information on 
	years of education for at least 2/3 of the household members aged 10 years 
	and older */	
gen temp = 1 if eduyears!=. & age>=10 & age!=.
bysort	hh_id: egen no_missing_edu = sum(temp)
	/*Total household members who are 10 years and older with no missing 
	years of education */
gen temp2 = 1 if age>=10 & age!=.
bysort hh_id: egen hhs = sum(temp2)
	//Total number of household members who are 10 years and older 
replace no_missing_edu = no_missing_edu/hhs
replace no_missing_edu = (no_missing_edu>=2/3)
	/*Identify whether there is information on years of education for at 
	least 2/3 of the household members aged 10 years and older */
tab no_missing_edu, miss
label var no_missing_edu "No missing edu for at least 2/3 of the HH members aged 10 years & older"		
drop temp temp2 hhs


*** Standard MPI ***
/*The entire household is considered deprived if no household member 
aged 10 years or older has completed SIX years of schooling.*/
******************************************************************* 
gen	years_edu6 = (eduyears>=6)
replace years_edu6 = . if eduyears==.
bysort hh_id: egen hh_years_edu6_1 = max(years_edu6)
gen	hh_years_edu6 = (hh_years_edu6_1==1)
replace hh_years_edu6 = . if hh_years_edu6_1==.
replace hh_years_edu6 = . if hh_years_edu6==0 & no_missing_edu==0 
lab var hh_years_edu6 "Household has at least one member with 6 years of edu"


	
*** Destitution MPI ***
/*The entire household is considered deprived if no household member 
aged 10 years or older has completed at least one year of schooling.*/
******************************************************************* 
gen	years_edu1 = (eduyears>=1)
replace years_edu1 = . if eduyears==.
bysort	hh_id: egen hh_years_edu_u = max(years_edu1)
replace hh_years_edu_u = . if hh_years_edu_u==0 & no_missing_edu==0
lab var hh_years_edu_u "Household has at least one member with 1 year of edu"


********************************************************************************
*** Step 2.2 Child School Attendance ***
********************************************************************************

codebook hv121, tab (10)
clonevar attendance = hv121 
recode attendance (2=1) 
codebook attendance, tab (10)
replace attendance = 0 if (attendance==9 | attendance==.) & hv109==0 
replace attendance = . if  attendance==9 & hv109!=0



*** Standard MPI ***
/*The entire household is considered deprived if any school-aged 
child is not attending school up to class 8. */ 
******************************************************************* 
gen	child_schoolage = (age>=7 & age<=15)
	/*In Afghanistan, the official school entrance age to primary school 
	is 7 years. So, age range is 7-15 (=7+8)*/


	/*A control variable is created on whether there is no information on 
	school attendance for at least 2/3 of the school age children */
count if child_schoolage==1 & attendance==.
	//Understand how many eligible school aged children are not attending school 
gen temp = 1 if child_schoolage==1 & attendance!=.
	/*Generate a variable that captures the number of eligible school aged 
	children who are attending school */
bysort hh_id: egen no_missing_atten = sum(temp)	
	/*Total school age children with no missing information on school 
	attendance */
gen temp2 = 1 if child_schoolage==1	
bysort hh_id: egen hhs = sum(temp2)
	//Total number of household members who are of school age
replace no_missing_atten = no_missing_atten/hhs 
replace no_missing_atten = (no_missing_atten>=2/3)
	/*Identify whether there is missing information on school attendance for 
	more than 2/3 of the school age children */			
tab no_missing_atten, miss
label var no_missing_atten "No missing school attendance for at least 2/3 of the school aged children"		
drop temp temp2 hhs	
	
bysort hh_id: egen hh_children_schoolage = sum(child_schoolage)
replace hh_children_schoolage = (hh_children_schoolage>0) 
lab var hh_children_schoolage "Household has children in school age"

gen	child_not_atten = (attendance==0) if child_schoolage==1
replace child_not_atten = . if attendance==. & child_schoolage==1
bysort	hh_id: egen any_child_not_atten = max(child_not_atten)
gen	hh_child_atten = (any_child_not_atten==0) 
replace hh_child_atten = . if any_child_not_atten==.
replace hh_child_atten = 1 if hh_children_schoolage==0
replace hh_child_atten = . if hh_child_atten==1 & no_missing_atten==0 
lab var hh_child_atten "Household has all school age children up to class 8 in school"
tab hh_child_atten, miss


*** Destitution MPI ***
/*The entire household is considered deprived if any school-aged 
child is not attending school up to class 6. */ 
******************************************************************* 
gen	child_schoolage_6 = (age>=7 & age<=13)
	/*In Afghanistan, the official school entrance age is 7 years.  
	  So, age range for destitute measure is 7-13 (=7+6)  */

	
	/*A control variable is created on whether there is no information on 
	school attendance for at least 2/3 of the children attending school up to 
	class 6 */	
count if child_schoolage_6==1 & attendance==.
	//Understand how many eligible school aged children are not attending school 	
gen temp = 1 if child_schoolage_6==1 & attendance!=.
	/*Generate a variable that captures the number of eligible school aged 
	children who are attending school */
bysort hh_id: egen no_missing_atten_u = sum(temp)	
	/*Total school age children attending up to class 6 with no missing 
	information on school attendance */
gen temp2 = 1 if child_schoolage_6==1	
bysort hh_id: egen hhs = sum(temp2)
	/*Total number of household members who are of school age attending up to 
	class 6 */
replace no_missing_atten_u = no_missing_atten_u/hhs 
replace no_missing_atten_u = (no_missing_atten_u>=2/3)
	/*Identify whether there is missing information on school attendance for 
	more than 2/3 of the school age children attending up to class 6 */			
tab no_missing_atten_u, miss
label var no_missing_atten_u "No missing school attendance for at least 2/3 of the school aged children"		
drop temp temp2 hhs		
	
	
bysort	hh_id: egen hh_children_schoolage_6 = sum(child_schoolage_6)
replace hh_children_schoolage_6 = (hh_children_schoolage_6>0) 
lab var hh_children_schoolage_6 "Household has children in school age (6 years of school)"

gen	child_atten_6 = (attendance==1) if child_schoolage_6==1
replace child_atten_6 = . if attendance==. & child_schoolage_6==1
bysort	hh_id: egen any_child_atten_6 = max(child_atten_6)
gen	hh_child_atten_u = (any_child_atten_6==1) 
replace hh_child_atten_u = . if any_child_atten_6==.
replace hh_child_atten_u = 1 if hh_children_schoolage_6==0
replace hh_child_atten_u = . if hh_child_atten_u==0 & no_missing_atten_u==0 
lab var hh_child_atten_u "Household has at least one school age children up to class 6 in school"
tab hh_child_atten_u, miss


********************************************************************************
*** Step 2.3 Nutrition ***
********************************************************************************
	/*Afghanistan DHS 2015-16 has no information on nutrition. As such, the 
	variables under this section are generated as empty variables */

gen	underweight = .
lab var underweight  "Child is undernourished (weight-for-age) 2sd - WHO"

gen stunting = .
lab var stunting "Child is stunted (length/height-for-age) 2sd - WHO"

gen wasting = .
lab var wasting  "Child is wasted (weight-for-length/height) 2sd - WHO"

gen	underweight_u = . 
lab var underweight_u  "Child is undernourished (weight-for-age) 3sd - WHO"

gen stunting_u = .
lab var stunting_u "Child is stunted (length/height-for-age) 3sd - WHO"

gen wasting_u = .
lab var wasting_u  "Child is wasted (weight-for-length/height) 3sd - WHO"
	
gen	f_bmi = .
lab var f_bmi "Women's BMI"	

gen m_bmi = .
lab var m_bmi "Male's BMI "	

gen hh_no_low_bmiage = . 
lab var hh_no_low_bmiage "Household has no adult with low BMI or BMI-for-age"

gen	hh_no_low_bmiage_u = .
lab var hh_no_low_bmiage_u "Household has no adult with low BMI or BMI-for-age (<17)"	
		
gen low_bmiage = . 
gen low_bmiage_u = . 
gen low_bmi_byage = .

	
gen hh_no_underweight = .
lab var hh_no_underweight "Household has no child underweight - 2 stdev"

gen hh_no_stunting  = .
lab var hh_no_stunting "Household has no child stunted - 2 stdev"

gen	hh_no_wasting = .
lab var hh_no_wasting "Household has no child wasted - 2 stdev"

gen hh_no_uw_st  = .
lab var hh_no_uw_st "Household has no child underweight or stunted"

gen	hh_no_underweight_u = .
lab var hh_no_underweight_u "Destitute: Household has no child underweight"

gen	hh_no_stunting_u = .
lab var hh_no_stunting_u "Destitute: Household has no child stunted"

gen	hh_no_wasting_u = .
lab var hh_no_wasting_u "Destitute: Household has no child wasted"

gen	hh_no_uw_st_u = .
lab var hh_no_uw_st_u "Destitute: Household has no child underweight or stunted"

gen	hh_nutrition_uw_st = .
lab var hh_nutrition_uw_st "Household has no child underweight/stunted or adult deprived by BMI/BMI-for-age"

gen	hh_nutrition_uw_st_u = .
lab var hh_nutrition_uw_st_u "Household has no child underweight/stunted or adult deprived by BMI/BMI-for-age (destitute)"

gen weight_ch = .	
gen fem_nutri_eligible = .
gen no_fem_nutri_eligible = .
gen male_nutri_eligible = .
gen no_male_nutri_eligible = .

********************************************************************************
*** Step 2.4 Child Mortality ***
********************************************************************************

codebook v206 v207 mv206 mv207
	/*v206 or mv206: number of sons who have died 
	  v207 or mv207: number of daughters who have died */
	

	//Total child mortality reported by eligible women
egen temp_f = rowtotal(v206 v207), missing
replace temp_f = 0 if v201==0
bysort	hh_id: egen child_mortality_f = sum(temp_f), missing
lab var child_mortality_f "Occurrence of child mortality reported by women"
tab child_mortality_f, miss
drop temp_f
	
	
	//Total child mortality reported by eligible men	
egen temp_m = rowtotal(mv206 mv207), missing
replace temp_m = 0 if mv201==0
bysort	hh_id: egen child_mortality_m = sum(temp_m), missing
lab var child_mortality_m "Occurrence of child mortality reported by men"
tab child_mortality_m, miss
drop temp_m


egen child_mortality = rowmax(child_mortality_f child_mortality_m)
lab var child_mortality "Total child mortality within household reported by women & men"
tab child_mortality, miss	
	
	
*** Standard MPI *** 
/* Members of the household are considered deprived if women 
in the household reported mortality among children under 18 
in the last 5 years from the survey year. */
************************************************************************
tab childu18_died_per_wom_5y, miss

replace childu18_died_per_wom_5y = 0 if v201==0 
	/*Assign a value of "0" for:
	- all eligible women who never ever gave birth */	
replace childu18_died_per_wom_5y = 0 if no_fem_eligible==1 
	/*Assign a value of "0" for:
	- individuals living in households that have non-eligible women */	
	
bysort hh_id: egen childu18_mortality_5y = sum(childu18_died_per_wom_5y), missing
replace childu18_mortality_5y = 0 if childu18_mortality_5y==. & child_mortality==0
label var childu18_mortality_5y "Under 18 child mortality within household past 5 years reported by women"
tab childu18_mortality_5y, miss		
	
gen hh_mortality_u18_5y = (childu18_mortality_5y==0)
replace hh_mortality_u18_5y = . if childu18_mortality_5y==.
lab var hh_mortality_u18_5y "Household had no under 18 child mortality in the last 5 years"
tab hh_mortality_u18_5y, miss 


*** Destitution MPI *** 
*** (same as standard MPI) ***
************************************************************************
gen hh_mortality_u = hh_mortality_u18_5y	
lab var hh_mortality_u "Household had no under 18 child mortality in the last 5 years"	


*** Harmonised MPI ***
 	/*In the earlier survey, there is no birth history data. This means, 
	there is no information on the date of death of children who have died. 
	As such, we are not able to construct the indicator on child mortality 
	under 18 that occurred in the last 5 years for this survey. Instead, 
	we identify individuals as deprived if any children died in the household. 
	As such, for harmonisation purpose, we construct the same indicator in 
	this survey.*/
************************************************************************
	
egen temp_f_c = rowtotal(v206 v207), missing
replace temp_f_c = 0 if v201==0
replace temp_f_c = 0 if hv115==0 & hv104==2 & hv105>=15 & hv105<=49	
bysort	hh_id: egen child_mortality_f_c = sum(temp_f_c), missing
lab var child_mortality_f_c "HOT: Occurrence of child mortality reported by women"
tab child_mortality_f_c, miss
drop temp_f_c	
	
egen child_mortality_c = rowmax(child_mortality_f_c child_mortality_m)
lab var child_mortality_c "HOT: Total child mortality within HH reported by women & men"
tab child_mortality_c, miss
	
	
gen	hh_mortality_c = (child_mortality_c==0)
replace hh_mortality_c = . if child_mortality_c==.
replace hh_mortality_c = 1 if no_fem_eligible==1 
lab var hh_mortality_c "COT: HH had no child mortality"
tab hh_mortality_c,m


clonevar hh_mortality_u_c = hh_mortality_c
lab var hh_mortality_u_c "COT-DST: HH had no child mortality"


********************************************************************************
*** Step 2.5 Electricity ***
********************************************************************************

*** Standard MPI ***
/*Members of the household are considered 
deprived if the household has no electricity */
***************************************************
clonevar electricity = hv206 
codebook electricity, tab (10)
replace electricity = . if electricity==9 
label var electricity "Household has electricity"



*** Destitution MPI  ***
*** (same as standard MPI) ***
***************************************************
gen electricity_u = electricity
label var electricity_u "Household has electricity"


********************************************************************************
*** Step 2.6 Sanitation ***
********************************************************************************

/*
Improved sanitation facilities include flush or pour flush toilets to sewer 
systems, septic tanks or pit latrines, ventilated improved pit latrines, pit 
latrines with a slab, and composting toilets. These facilities are only 
considered improved if it is private, that is, it is not shared with other 
households.
Source: https://unstats.un.org/sdgs/metadata/files/Metadata-06-02-01.pdf

Note: In cases of mismatch between the country report and the internationally 
agreed guideline, we followed the report.
*/

clonevar toilet = hv205   
codebook hv225, tab(30)  
clonevar shared_toilet = hv225 

	
*** Standard MPI ***
/*Members of the household are considered deprived if the household's 
sanitation facility is not improved (according to the SDG guideline) 
or it is improved but shared with other households*/
********************************************************************
codebook toilet, tab(30)

gen	toilet_mdg     =      (toilet<23 | toilet==41) & shared_toilet!=1	
replace toilet_mdg = 0 if (toilet<23 | toilet==41)  & shared_toilet==1   	
replace toilet_mdg = 0 if toilet==14 | toilet==15
replace toilet_mdg = . if toilet==.  | toilet==99	
lab var toilet_mdg "Household has improved sanitation with MDG Standards"
tab toilet toilet_mdg, miss


*** Destitution MPI ***
/*Members of the household are considered deprived if household practises 
open defecation or uses other unidentifiable sanitation practises */
********************************************************************
gen	toilet_u = .
replace toilet_u = 0 if toilet==31 | toilet==96 	
replace toilet_u = 1 if toilet!=31 & toilet!=96 & toilet!=. & toilet!=99	
lab var toilet_u "Household does not practise open defecation or others"
tab toilet toilet_u, miss


********************************************************************************
*** Step 2.7 Drinking Water  ***
********************************************************************************
/*
Improved drinking water sources include the following: piped water into 
dwelling, yard or plot; public taps or standpipes; boreholes or tubewells; 
protected dug wells; protected springs; packaged water; delivered water and 
rainwater which is located on premises or is less than a 30-minute walk from 
home roundtrip. 
Source: https://unstats.un.org/sdgs/metadata/files/Metadata-06-01-01.pdf

Note: In cases of mismatch between the country report and the internationally 
agreed guideline, we followed the report.
*/

clonevar water = hv201  
clonevar timetowater = hv204  
codebook water, tab(100)	
clonevar ndwater = hv202  
	//No observation for non-drinking water
	

*** Standard MPI ***
/* Members of the household are considered deprived if the household 
does not have access to improved drinking water (according to the SDG 
guideline) or safe drinking water is at least a 30-minute walk from 
home, roundtrip */
********************************************************************
gen	water_mdg    = 1  if water==11 | water==12 | water==14 | water==21 | ///
					     water==31 | water==41 | water==51 | water==71 
	
replace water_mdg = 0 if water==32 | water==42 | water==43 | ///
						 water==61 | water==62 | water==96 
	
replace water_mdg = 0 if water_mdg==1 & timetowater >= 30 & timetowater!=. & ///
						 timetowater!=996 & timetowater!=998 & timetowater!=999 

replace water_mdg = . if water==. | water==99
lab var water_mdg "Household has drinking water with MDG standards (considering distance)"
tab water water_mdg, miss


*** Destitution MPI ***
/* Members of the household is identified as destitute if household 
does not have access to safe drinking water, or safe water is more 
than 45 minute walk from home, round trip.*/
********************************************************************
gen	water_u = .
replace water_u = 1 if water==11 | water==12 | water==14 | water==21 | ///
					   water==31 | water==41 | water==51 | water==71 
						   
replace water_u = 0 if water==32 | water==42 | water==43 | ///
					   water==61 | water==62 | water==96
						   
replace water_u = 0 if water_u==1 & timetowater>45 & timetowater!=. & ///
					   timetowater!=995 & timetowater!=996 & ///
					   timetowater!=998 & timetowater!=999
						   
replace water_u = . if water==. | water==99						  
lab var water_u "Household has drinking water with MDG standards (45 minutes distance)"
tab water water_u, miss

********************************************************************************
*** Step 2.8 Housing ***
********************************************************************************

/* Members of the household are considered deprived if the household 
has a dirt, sand or dung floor */
clonevar floor = hv213 
codebook floor, tab(99)
gen	floor_imp = 1
replace floor_imp = 0 if floor<=13 | floor==96  
replace floor_imp = . if floor==.  | floor==99 	
lab var floor_imp "Household has floor that it is not earth/sand/dung"
tab floor floor_imp, miss		


/* Members of the household are considered deprived if the household has walls 
made of natural or rudimentary materials */
clonevar wall = hv214 
codebook wall, tab(99)	
gen	wall_imp = 1 
replace wall_imp = 0 if wall<=26 | wall==96  	
replace wall_imp = . if wall==.  | wall==99 	
lab var wall_imp "Household has wall that it is not of low quality materials"
tab wall wall_imp, miss	
	
	
/* Members of the household are considered deprived if the household has roof 
made of natural or rudimentary materials */
clonevar roof = hv215
codebook roof, tab(99)	
gen	roof_imp = 1 
replace roof_imp = 0 if roof<=24 | roof==96  
replace roof_imp = . if roof==.  | roof==99 	
lab var roof_imp "Household has roof that it is not of low quality materials"
tab roof roof_imp, miss


*** Standard MPI ***
/* Members of the household is deprived in housing if the roof, 
floor OR walls are constructed from low quality materials.*/
**************************************************************
gen housing_1 = 1
replace housing_1 = 0 if floor_imp==0 | wall_imp==0 | roof_imp==0
replace housing_1 = . if floor_imp==. & wall_imp==. & roof_imp==.
lab var housing_1 "Household has roof, floor & walls that it is not low quality material"
tab housing_1, miss


*** Destitution MPI ***
/* Members of the household is deprived in housing if two out 
of three components (roof and walls; OR floor and walls; OR 
roof and floor) the are constructed from low quality materials. */
**************************************************************
gen housing_u = 1
replace housing_u = 0 if (floor_imp==0 & wall_imp==0 & roof_imp==1) | ///
						 (floor_imp==0 & wall_imp==1 & roof_imp==0) | ///
						 (floor_imp==1 & wall_imp==0 & roof_imp==0) | ///
						 (floor_imp==0 & wall_imp==0 & roof_imp==0)
replace housing_u = . if floor_imp==. & wall_imp==. & roof_imp==.
lab var housing_u "Household has one of three aspects(either roof,floor/walls) that is not low quality material"
tab housing_u, miss


********************************************************************************
*** Step 2.9 Cooking Fuel ***
********************************************************************************
/*
Solid fuel are solid materials burned as fuels, which includes coal as well as 
solid biomass fuels (wood, animal dung, crop wastes and charcoal). 

Source: 
https://apps.who.int/iris/bitstream/handle/10665/141496/9789241548885_eng.pdf
*/

clonevar cookingfuel = hv226  
codebook cookingfuel, tab(99)


*** Standard MPI ***
/* Members of the household are considered deprived if the 
household uses solid fuels and solid biomass fuels for cooking. */
*****************************************************************
gen	cooking_mdg = 1
replace cooking_mdg = 0 if cookingfuel>5 & cookingfuel<95 
replace cooking_mdg = . if cookingfuel==. | cookingfuel==99
lab var cooking_mdg "Household has cooking fuel by MDG standards"			 
tab cookingfuel cooking_mdg, miss	


*** Destitution MPI ***
*** (same as standard MPI) ***
****************************************
gen	cooking_u = cooking_mdg
lab var cooking_u "Household uses clean fuels for cooking"


********************************************************************************
*** Step 2.10 Assets ownership ***
********************************************************************************
/*Assets that are included in the global MPI: Radio, TV, telephone, bicycle, 
motorbike, refrigerator, car, computer and animal cart */


clonevar television = hv208 
gen bw_television   = .
clonevar radio = hv207 
clonevar telephone =  hv221 
clonevar mobiletelephone = hv243a  
clonevar refrigerator = hv209 
clonevar car = hv212  	
clonevar bicycle = hv210 
clonevar motorbike = hv211 
clonevar computer = hv243e
clonevar animal_cart = hv243c



foreach var in television radio telephone mobiletelephone refrigerator ///
			   car bicycle motorbike computer animal_cart  {
replace `var' = . if `var'==9 | `var'==99 | `var'==8 | `var'==98 
}
	//Missing values replaced

	
	//Combine information on telephone and mobiletelephone
replace telephone=1 if telephone==0 & mobiletelephone==1
replace telephone=1 if telephone==. & mobiletelephone==1


	//label indicators
lab var television "Household has television"
lab var radio "Household has radio"	
lab var telephone "Household has telephone (landline/mobilephone)"	
lab var refrigerator "Household has refrigerator"
lab var car "Household has car"
lab var bicycle "Household has bicycle"	
lab var motorbike "Household has motorbike"
lab var computer "Household has computer"
lab var animal_cart "Household has animal cart"
	

	
*** Standard MPI ***
/* Members of the household are considered deprived in assets if the household 
does not own more than one of: radio, TV, telephone, bike, motorbike, 
refrigerator, computer or animal cart and does not own a car or truck.*/
*****************************************************************************
egen n_small_assets2 = rowtotal(television radio telephone refrigerator bicycle motorbike computer animal_cart), missing
lab var n_small_assets2 "Household Number of Small Assets Owned" 
    
gen hh_assets2 = (car==1 | n_small_assets2 > 1) 
replace hh_assets2 = . if car==. & n_small_assets2==.
lab var hh_assets2 "Household Asset Ownership: HH has car or more than 1 small assets incl computer & animal cart"



*** Destitution MPI ***
/* Members of the household are considered deprived in assets if the household 
does not own any assets.*/
*****************************************************************************
gen	hh_assets2_u = (car==1 | n_small_assets2>0)
replace hh_assets2_u = . if car==. & n_small_assets2==.
lab var hh_assets2_u "Household Asset Ownership: HH has car or at least 1 small assets incl computer & animal cart"


*** Harmonised MPI *** 
	/*The earlier survey lacked information on computer. As 
	such, the harmonised work excludes computer.*/
************************************************************************
gen computer_c = .
lab var computer_c "COT: Household has computer"

egen n_small_assets2_c = rowtotal(television radio telephone refrigerator bicycle motorbike computer_c animal_cart), missing
lab var n_small_assets2_c "COT: HH Number of Small Assets Owned" 
    
gen hh_assets2_c = (car==1 | n_small_assets2_c > 1) 
replace hh_assets2_c = . if car==. & n_small_assets2_c==.
lab var hh_assets2_c "COT: HH has car or more than 1 small assets"

gen	hh_assets2_u_c = (car==1 | n_small_assets2_c>0)
replace hh_assets2_u_c = . if car==. & n_small_assets2_c==.
lab var hh_assets2_u_c "COT-DST: HH has car or at least 1 small assets"


	
********************************************************************************
*** Step 2.11 Rename and keep variables for MPI calculation 
********************************************************************************

	//Retain DHS wealth index:
desc hv270 	
clonevar windex=hv270

desc hv271
clonevar windexf=hv271


	//Retain data on sampling design: 
desc hv022 hv021	
clonevar strata = hv022
clonevar psu = hv021
label var psu "Primary sampling unit"
label var strata "Sample strata"


	//Retain year, month & date of interview:
desc hv007 hv006 hv008
clonevar year_interview = hv007 	
clonevar month_interview = hv006 
clonevar date_interview = hv008
 
 
*** Rename key global MPI indicators for estimation ***
recode hh_mortality_u18_5y  (0=1)(1=0) , gen(d_cm)
recode hh_nutrition_uw_st 	(0=1)(1=0) , gen(d_nutr)
recode hh_child_atten 		(0=1)(1=0) , gen(d_satt)
recode hh_years_edu6 		(0=1)(1=0) , gen(d_educ)
recode electricity 			(0=1)(1=0) , gen(d_elct)
recode water_mdg 			(0=1)(1=0) , gen(d_wtr)
recode toilet_mdg 			(0=1)(1=0) , gen(d_sani)
recode housing_1 			(0=1)(1=0) , gen(d_hsg)
recode cooking_mdg 			(0=1)(1=0) , gen(d_ckfl)
recode hh_assets2 			(0=1)(1=0) , gen(d_asst)
 

*** Rename key global MPI indicators for destitution estimation ***
recode hh_mortality_u       (0=1)(1=0) , gen(dst_cm)
recode hh_nutrition_uw_st_u (0=1)(1=0) , gen(dst_nutr)
recode hh_child_atten_u 	(0=1)(1=0) , gen(dst_satt)
recode hh_years_edu_u 		(0=1)(1=0) , gen(dst_educ)
recode electricity_u		(0=1)(1=0) , gen(dst_elct)
recode water_u 				(0=1)(1=0) , gen(dst_wtr)
recode toilet_u 			(0=1)(1=0) , gen(dst_sani)
recode housing_u 			(0=1)(1=0) , gen(dst_hsg)
recode cooking_u			(0=1)(1=0) , gen(dst_ckfl)
recode hh_assets2_u 		(0=1)(1=0) , gen(dst_asst) 


*** Rename indicators for changes over time estimation ***	
recode hh_mortality_c       (0=1)(1=0) , gen(d_cm_01)
recode hh_nutrition_uw_st 	(0=1)(1=0) , gen(d_nutr_01)
recode hh_child_atten 		(0=1)(1=0) , gen(d_satt_01)
recode hh_years_edu6 		(0=1)(1=0) , gen(d_educ_01)
recode electricity 			(0=1)(1=0) , gen(d_elct_01)
recode water_mdg 			(0=1)(1=0) , gen(d_wtr_01)
recode toilet_mdg 			(0=1)(1=0) , gen(d_sani_01)
recode housing_1 			(0=1)(1=0) , gen(d_hsg_01)
recode cooking_mdg 			(0=1)(1=0) , gen(d_ckfl_01)
recode hh_assets2_c 		(0=1)(1=0) , gen(d_asst_01)	
	

recode hh_mortality_u_c      (0=1)(1=0) , gen(dst_cm_01)
recode hh_nutrition_uw_st_u (0=1)(1=0) , gen(dst_nutr_01)
recode hh_child_atten_u 	(0=1)(1=0) , gen(dst_satt_01)
recode hh_years_edu_u 		(0=1)(1=0) , gen(dst_educ_01)
recode electricity_u		(0=1)(1=0) , gen(dst_elct_01)
recode water_u	 			(0=1)(1=0) , gen(dst_wtr_01)
recode toilet_u 			(0=1)(1=0) , gen(dst_sani_01)
recode housing_u 			(0=1)(1=0) , gen(dst_hsg_01)
recode cooking_u			(0=1)(1=0) , gen(dst_ckfl_01)
recode hh_assets2_u_c 		(0=1)(1=0) , gen(dst_asst_01) 


	/*In this survey, the region variable is 
	harmonised over time.*/	
clonevar region_01 = region_c 


*** Keep main variables require for MPI calculation ***
keep hh_id ind_id psu strata subsample weight ///
area region region_01 agec4 agec2 headship ///
d_cm d_nutr d_satt d_educ d_elct d_wtr d_sani d_hsg d_ckfl d_asst /// 
d_cm_01 d_nutr_01 d_satt_01 d_educ_01 ///
d_elct_01 d_wtr_01 d_sani_01 d_hsg_01 d_ckfl_01 d_asst_01


order hh_id ind_id psu strata subsample weight ///
area region region_01 agec4 agec2 headship ///
d_cm d_nutr d_satt d_educ d_elct d_wtr d_sani d_hsg d_ckfl d_asst ///
d_cm_01 d_nutr_01 d_satt_01 d_educ_01 ///
d_elct_01 d_wtr_01 d_sani_01 d_hsg_01 d_ckfl_01 d_asst_01

	
*** Generate coutry and survey details for estimation ***
char _dta[cty] "Afghanistan"
char _dta[ccty] "AFG"
char _dta[year] "2015-2016" 	
char _dta[survey] "DHS"
char _dta[ccnum] "004"
char _dta[type] "micro"


*** Sort, compress and save data for estimation ***
sort ind_id
compress
la da "Micro data for `_dta[ccty]' (`_dta[ccnum]') from `c(current_date)' (`c(current_time)')."
save "$path_out/afg_dhs15-16.dta", replace 


/******************************************************************************
	Purpose: Computing the deprivations to be used for the estimation of 
        the Global Multi-dimensional Poverty Index (MPI). 
	Data input: The model datasets are found in MICS Afghanistan 2011. 
	Date Last Modified: August 29, 2023 by Albert Lutakome
        Credits to: Oxford Poverty & Human Development Initiative (OPHI)

Notes/Instructions:
*******************************************************************************/
clear all 
set more off
set maxvar 100000


*** Working Folder Path ***
global path_in "..\Documents\Indices\MPI" 
global path_out "cdta"
// global path_out "$path_in\DTA"
	
********************************************************************************
*** AFGHANISTAN MICS 2011 ***
********************************************************************************

********************************************************************************
*** Step 1: Data preparation 
*** Selecting main variables from CH, WM, HH & MN recode & merging with HL recode 
********************************************************************************
		

********************************************************************************
*** Step 1.1 CH - CHILD RECODE
*** (Children under 5 years) 
********************************************************************************

	//No anthropometric data for children


********************************************************************************
*** Step 1.2  BH - BIRTH RECODE 
*** (All females 15-49 years who ever gave birth)  
********************************************************************************

	//No birth recode

	
********************************************************************************
*** Step 1.3  WM - WOMEN's RECODE  
*** (Eligible females 15-49 years in the household)
********************************************************************************


use "$path_in/wm.dta", clear 
	
rename _all, lower	

	
*** Generate individual unique key variable required for data merging using:
	*** hh1=cluster number; 
	*** hh2=household number; 
	*** wm4=women's line number.  
gen double ind_id = hh1*1000000 + hh2*100 + wm4 
format ind_id %20.0g
label var ind_id "Individual ID"

duplicates report ind_id

gen women_WM =1 
	//Identification variable for observations in WM recode


codebook mstatus ma6, tab (10)
tab mstatus ma6, miss 
gen marital = 1 if mstatus == 3 & ma6==.
	//1: Never married
replace marital = 2 if mstatus == 1 & ma6==.
	//2: Currently married
replace marital = 3 if mstatus == 2 & ma6==1
	//3: Widowed	
replace marital = 4 if mstatus == 2 & ma6==2
	//4: Divorced	
replace marital = 5 if mstatus == 2 & ma6==3
	//5: Separated/not living together
replace mstatus = . if mstatus==9 
	//Replace any missing values 	
label define lab_mar 1"never married" 2"currently married" 3"widowed" ///
4"divorced" 5"not living together"
label values marital lab_mar	
label var marital "Marital status of household member"
tab marital, miss
tab ma6 marital, miss
tab mstatus marital, miss
rename marital marital_wom
	
	
keep wm7* wm6a wb2 cm1 cm8 cm9a cm9b ind_id women_WM *_wom
order wm7* wm6a wb2 cm1 cm8 cm9a cm9b ind_id women_WM *_wom
sort ind_id
save "$path_out/AFG11_WM.dta", replace


	
********************************************************************************
*** Step 1.4  MN - MEN'S RECODE 
***(Eligible man: 15-59 years in the household) 
********************************************************************************

	//No male recode data.


********************************************************************************
*** Step 1.5 HH - HOUSEHOLD RECODE 
***(All households interviewed) 
********************************************************************************

use "$path_in/hh.dta", clear 
	
rename _all, lower	


*** Generate individual unique key variable required for data merging
	*** hh1=cluster number;  
	*** hh2=household number 
gen	double hh_id = hh1*1000 + hh2 
format	hh_id %20.0g
lab var hh_id "Household ID"


duplicates report hh_id 

save "$path_out/AFG11_HH.dta", replace

	

********************************************************************************
*** Step 1.6 HL - HOUSEHOLD MEMBER  
********************************************************************************

use "$path_in/hl.dta", clear 

rename _all, lower

	
*** Generate a household unique key variable at the household level using: 
	***hh1=cluster number 
	***hh2=household number
gen double hh_id = hh1*1000 + hh2 
format hh_id %20.0g
label var hh_id "Household ID"


*** Generate individual unique key variable required for data merging using:
	*** hh1=cluster number; 
	*** hh2=household number; 
	*** hl1=respondent's line number.
gen double ind_id = hh1*1000000 + hh2*100 + hl1 
format ind_id %20.0g
label var ind_id "Individual ID"

duplicates report ind_id 

sort ind_id
save "$path_out/AFG11_HHM.dta", replace
********************************************************************************
*** Step 1.7 DATA MERGING 
******************************************************************************** 
 

 
*** Merging WM Recode 
*****************************************
merge 1:1 ind_id using "$path_out/AFG11_WM.dta"
drop _merge
erase "$path_out/AFG11_WM.dta"


*** Merging HH Recode 
*****************************************
merge m:1 hh_id using "$path_out/AFG11_HH.dta"

drop  if _merge==2
	//Drop households that were not interviewed 
drop _merge
erase "$path_out/AFG11_HH.dta"


*** Merging MN Recode 
*****************************************
gen marital_men = .
label var marital_men "Marital status of household member"


sort ind_id


********************************************************************************
*** Step 1.8 CONTROL VARIABLES
********************************************************************************


*** No eligible women 15-49 years 
*** for child mortality indicator
*****************************************
gen	fem_eligible = (women_WM==1) & marital_wom!=1 & marital_wom!=.
bys	hh_id: egen hh_n_fem_eligible = sum(fem_eligible) 	
gen	no_fem_eligible = (hh_n_fem_eligible==0) 									
lab var no_fem_eligible "Household has no eligible women"
drop hh_n_fem_eligible 
tab no_fem_eligible, miss


*** No eligible men 15-49 years
*** for child mortality indicator (if relevant)
*****************************************
gen	male_eligible = .
gen	no_male_eligible = .
lab var no_male_eligible "Household has no eligible man for interview"

	
*** No eligible children under 5
*** for child nutrition indicator
*****************************************
gen	child_eligible = .
gen	no_child_eligible = .
lab var no_child_eligible "Household has no children eligible for anthropometric"

sort hh_id

 
********************************************************************************
*** Step 1.11 RENAMING DEMOGRAPHIC VARIABLES ***
********************************************************************************

//Sample weight
clonevar weight = hhweight 
label var weight "Sample weight"


//Area: urban or rural		
desc hh6	
codebook hh6, tab (5)	
clonevar area = hh6  
replace area=0 if area==2  
label define lab_area 1 "urban" 0 "rural"
label values area lab_area
label var area "Area: urban-rural"


//Relationship to the head of household
desc hl3
clonevar relationship = hl3 
codebook relationship, tab (20)
recode relationship (1=1)(2=2)(3 13=3)(4/12=4)(14=5)(98 99=.)
label define lab_rel 1"head" 2"spouse" 3"child" 4"extended family" ///
5"not related" 6"maid"
label values relationship lab_rel
label var relationship "Relationship to the head of household"
tab hl3 relationship, miss	


//Sex of household member
codebook hl4
clonevar sex = hl4 
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
codebook hl6, tab (999)
clonevar age = hl6  
replace age = . if age>=98
label var age "Age of household member"


//Age group (for global MPI estimation)
recode age (0/4 = 1 "0-4")(5/9 = 2 "5-9")(10/14 = 3 "10-14") ///
		   (15/17 = 4 "15-17")(18/59 = 5 "18-59")(60/max=6 "60+"), gen(agec7)
lab var agec7 "age groups (7 groups)"	
	   
recode age (0/9 = 1 "0-9") (10/17 = 2 "10-17")(18/59 = 3 "18-59") ///
		   (60/max=4 "60+") , gen(agec4)
lab var agec4 "age groups (4 groups)"

recode age (0/17 = 1 "0-17") (18/max = 2 "18+"), gen(agec2)		 		   
lab var agec2 "age groups (2 groups)"


//Total number of de jure hh members in the household
gen member = 1
bysort hh_id: egen hhsize = sum(member)
label var hhsize "Household size"
tab hhsize, miss
compare hhsize hh11


//Subnational region
	/*The survey was designed to produce representative for Afghanistan 
	as a whole, for urban and rural areas, and for each of the country's 
	eight regions (p.4).*/  
	
codebook hh7, tab (99)
recode hh7 (1=1 "Central")(2=2 "Central Highlands")(3=3 "East")(4=4 "North") ///
(5=5 "North East")(6=6 "South")(7=7 "South East")(8=8 "West"), gen(region)
lab var region "Region for subnational decomposition"
tab hh7 region, m
tab region, miss


********************************************************************************
***  Step 2 Data preparation  ***
***  Standardization of the 10 Global MPI indicators 
***  Identification of non-deprived & deprived individuals  
********************************************************************************

********************************************************************************
*** Step 2.1 Years of Schooling ***
********************************************************************************


	/* In Afghanistan, compulsory education lasts nine years 
	(primary + lower secondary). Admission age to primary education is 7. 
	Primary education lasts six years (grades 1 to 6). Lower secondary 
	education lasts three years (grades 7-9) and upper secondary education 
	lasts three years (grades 10-12). 
	Reference: http://data.uis.unesco.org/?ReportId=163#*/

codebook ed4a, tab (99)
tab age ed6a if ed4a==0, miss
	//The category Preschool indicates early childhood education, that is, pre-primary
clonevar edulevel = ed4a 
	//Highest educational level attended
replace edulevel = . if ed4a==. | ed4a==8 | ed4a==9  
	//All missing values or out of range are replaced as "."
replace edulevel = 0 if ed3==2 
	//Those who never attended school are replaced as '0'
label var edulevel "Highest level of education attended"


codebook ed4b, tab (99)
clonevar eduhighyear = ed4b 
	//Highest grade attended at that level
replace eduhighyear = .  if ed4b==. | ed4b==99 
	//All missing values or out of range are replaced as "."
replace eduhighyear = 0  if ed3==2 
	//Those who never attended school are replaced as '0'
lab var eduhighyear "Highest grade attended for each level of edu"


*** Cleaning inconsistencies
replace edulevel = 0 if age<10  
replace eduhighyear = 0 if age<10 
	/*The variables edulevel and eduhighyear was replaced with a '0' given that 
	the criteria for this indicator is household member aged 10 years or older */ 
replace eduhighyear = 0 if edulevel<1
	//Early childhood education has no grade

	
*** Now we create the years of schooling
tab eduhighyear edulevel, miss
	// Secondary and higher education already coded according to correct grades
	// Over half of the total number of individuals never attended school
gen	eduyears = eduhighyear
replace eduyears = 0 if edulevel<=1 & eduhighyear==.   
	/*Assuming 0 year if they only attend preschool or primary but the last year 
	is unknown*/ 
replace eduyears = 0 if edulevel== 0 & eduyears==. 
replace eduyears = . if edulevel==. & eduhighyear==. 
	//Replaced as missing value when level of education is missing

	
*** Checking for further inconsistencies 
replace eduyears = . if age<=eduyears & age>0 
	/*There are cases in which the years of schooling are greater than the 
	age of the individual. This is clearly a mistake in the data. Please check 
	whether this is the case and correct when necessary */
replace eduyears = 0 if age< 10 
	/*The variable "eduyears" was replaced with a '0' given that the criteria 
	for this indicator is household member aged 10 years or older */
replace eduyears = . if edulevel==. & ed3==1
	/*Replaced as missing value when level of education is missing for those 
	who have attended school */
lab var eduyears "Total number of years of education accomplished"
tab eduyears edulevel, miss


	/*A control variable is created on whether there is information on 
	years of education for at least 2/3 of the household members aged 10 years 
	and older */	
gen temp = 1 if eduyears!=. & age>=10 & age!=.
bysort	hh_id: egen no_missing_edu = sum(temp)
	/*Total household members who are 10 years and older with no missing 
	years of education */
gen temp2 = 1 if age>=10 & age!=.
bysort hh_id: egen hhs = sum(temp2)
	/*Total number of household members who are 10 years and older */
replace no_missing_edu = no_missing_edu/hhs
replace no_missing_edu = (no_missing_edu>=2/3)
	/*Identify whether there is information on years of education for at 
	least 2/3 of the household members aged 10 years and older */
tab no_missing_edu, miss
label var no_missing_edu "No missing edu for at least 2/3 of the HH members aged 10 years & older"	
drop temp temp2 hhs


*** Standard MPI ***
/*The entire household is considered deprived if no household member aged 
10 years or older has completed SIX years of schooling. */
******************************************************************* 
gen	 years_edu6 = (eduyears>=6)
replace years_edu6 = . if eduyears==.
bysort hh_id: egen hh_years_edu6_1 = max(years_edu6)
// by sorting with hh_id, max entires per hh will be entered in rows per hh. 
gen	hh_years_edu6 = (hh_years_edu6_1==1)
replace hh_years_edu6 = . if hh_years_edu6_1==.
replace hh_years_edu6 = . if hh_years_edu6==0 & no_missing_edu==0 
lab var hh_years_edu6 "Household has at least one member with 6 years of edu"
tab hh_years_edu6, miss

	
*** Destitution MPI ***
/*The entire household is considered deprived if no household member 
aged 10 years or older has completed at least one year of schooling. */
******************************************************************* 
gen	years_edu1 = (eduyears>=1)
replace years_edu1 = . if eduyears==.
bysort	hh_id: egen hh_years_edu_u = max(years_edu1) // gen max edu years of hh
replace hh_years_edu_u = . if hh_years_edu_u==0 & no_missing_edu==0
lab var hh_years_edu_u "Household has at least one member with 1 year of edu"



********************************************************************************
*** Step 2.2 Child School Attendance ***
********************************************************************************
	
codebook ed3 ed5, tab (99)

gen	attendance = .
replace attendance = 1 if ed5==1 
	//Replace attendance with '1' if currently attending school	
replace attendance = 0 if ed5==2 
	//Replace attendance with '0' if currently not attending school	
replace attendance = 0 if ed3==2 
	//Replace attendance with '0' if never ever attended school		
replace attendance = 0 if age<5 | age>24 
	//Replace attendance with '0' for individuals who are not of school age		
tab attendance, miss
label define lab_attend 1 "currently attending" 0 "not currently attending"
label values attendance lab_attend
label var attendance "Attended school during current school year"


*** Standard MPI ***
/*The entire household is considered deprived if any school-aged child is not 
attending school up to class 8. */ 
******************************************************************* 

gen	child_schoolage = (age>=7 & age<=15)
	/*In Afghanistan, the official school entrance age is 7 years (p.112).
	  So, age range is 7-15 (=7+8) */

	
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
	/*In Afghanistan, the official school entrance age is 7 years  
	  So, age range is 7-13 (=7+6) */

	
	/*A control variable is created on whether there is no information on 
	school attendance for at least 2/3 of the children attending school up to 
	class 6 */	
count if child_schoolage_6==1 & attendance==.	
gen temp = 1 if child_schoolage_6==1 & attendance!=.
bysort hh_id: egen no_missing_atten_u = sum(temp)	
gen temp2 = 1 if child_schoolage_6==1	
bysort hh_id: egen hhs = sum(temp2)
replace no_missing_atten_u = no_missing_atten_u/hhs 
replace no_missing_atten_u = (no_missing_atten_u>=2/3)			
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
 
	/*This survey has no information on nutrition. As such, the final 
	sets of nutrition indicators in this survey, generated as part of 
	the global MPI task are assigned with missing observations */
	
	
gen underweight = .
lab var underweight  "Child is undernourished (weight-for-age) 2sd - WHO"

gen stunting=.
lab var stunting "Child is stunted (length/height-for-age) 2sd - WHO"

gen wasting=.
lab var wasting  "Child is wasted (weight-for-length/height) 2sd - WHO"

gen underweight_u = .
lab var underweight_u  "Child is undernourished (weight-for-age) 3sd - WHO"

gen stunting_u=. 
lab var stunting_u "Child is stunted (length/height-for-age) 3sd - WHO"

gen wasting_u=.
lab var wasting_u  "Child is wasted (weight-for-length/height) 3sd - WHO"


gen hh_no_underweight = .
lab var hh_no_underweight "Household has no child underweight - 2 stdev"

gen hh_no_stunting  = .
lab var hh_no_stunting "Household has no child stunted - 2 stdev"

gen hh_no_wasting = .
lab var hh_no_wasting "Household has no child wasted - 2 stdev"

gen	hh_no_underweight_u = .
lab var hh_no_underweight_u "Destitute: Household has no child underweight"

gen	hh_no_stunting_u = .
lab var hh_no_stunting_u "Destitute: Household has no child stunted"

gen hh_no_wasting_u = .
lab var hh_no_wasting_u "Destitute: Household has no child wasted"

gen hh_no_uw_st = .
lab var hh_no_uw_st "Household has no child underweight or stunted"

gen hh_no_uw_st_u = .
lab var hh_no_uw_st_u "Destitute: Household has no child underweight or stunted"

gen	hh_nutrition_uw_st = .
lab var hh_nutrition_uw_st "Household has no child underweight/stunted or adult deprived by BMI/BMI-for-age"

gen	hh_nutrition_uw_st_u = .
lab var hh_nutrition_uw_st_u "Household has no child underweight/stunted or adult deprived by BMI/BMI-for-age (destitute)|"

gen weight_ch = .
label var weight_ch "sample weight child under 5"


********************************************************************************
*** Step 2.4 Child Mortality ***
********************************************************************************

codebook cm9a cm9b cm1 cm8
	/*cm9 or mcm9: number of sons who have died 
	  cm10 or mcm10: number of daughters who have died */
	  
egen temp_f = rowtotal(cm9a cm9b) if marital_wom!=1 & marital_wom!=., missing
	//Total child mortality reported by eligible women
replace temp_f = 0 if cm1==1 & cm8==2 | cm1==2 
	/*Assign a value of "0" for:
	- all eligible women who have ever gave birth but reported no child death 
	- all eligible women who never ever gave birth */
replace temp_f = 0 if no_fem_eligible==1	
	/*Assign a value of "0" for:
	- individuals living in households that have non-eligible women */
	
replace temp_f = 0 if marital_wom==1 & hl4==2 & hl6>=15 & hl6<=49
	//This line replaces never-married women with 0 child death. 	
bysort	hh_id: egen child_mortality_f = sum(temp_f), missing
lab var child_mortality_f "Occurrence of child mortality reported by women"
tab child_mortality_f, miss
drop temp_f	


gen child_mortality_m = .	
lab var child_mortality_m "Occurrence of child mortality reported by men"
tab child_mortality_m, miss

egen child_mortality = rowmax(child_mortality_f child_mortality_m)
lab var child_mortality "Total child mortality within household"
tab child_mortality, miss

	
*** Standard MPI *** 
	/*The usual definition for this indicator is that household members are
	identified as deprived if any children under 18 died in the household in 
	the last 5 years from the survey year. However, in the case of this 
	survey, there is no birth history data. This means, there is no information 
	on the date of death of children who have died. As such we are not able to 
	construct the indicator on child mortality under 18 that occurred in the 
	last 5 years. Instead, we identify individuals as deprived if any children 
	died in the household. */
************************************************************************
gen	hh_mortality = (child_mortality==0)
replace hh_mortality = . if child_mortality==.
replace hh_mortality = 1 if no_fem_eligible==1	
lab var hh_mortality "Household had no child mortality"
tab hh_mortality, miss


gen hh_mortality_u18_5y = .
lab var hh_mortality_u18_5y "Household had no under 18 child mortality in the last 5 years"


*** Destitution MPI *** 
*** (same as standard MPI) ***
************************************************************************
gen hh_mortality_u = hh_mortality	
lab var hh_mortality_u "Household had no child mortality"


********************************************************************************
*** Step 2.5 Electricity ***
********************************************************************************


*** Standard MPI ***
/*Members of the household are considered deprived 
if the household has no electricity */
****************************************
clonevar electricity = hc8a
codebook electricity, tab (9)
replace electricity = 0 if electricity==2
replace electricity = . if electricity==9 	
label var electricity "Household has electricity"


*** Destitution MPI  ***
*** (same as standard MPI) ***
****************************************
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
  
clonevar toilet = ws8 	
clonevar shared_toilet = ws9
codebook shared_toilet, tab(99)  
recode shared_toilet (2=0)
replace shared_toilet=. if shared_toilet==9

		
*** Standard MPI ***
/*Members of the household are considered deprived if the household's 
sanitation facility is not improved (according to the SDG guideline) 
or it is improved but shared with other households*/
********************************************************************
codebook toilet, tab(99) 

gen	toilet_mdg     =     (toilet<23  | toilet==31) & shared_toilet!=1	
replace toilet_mdg = 0 if toilet==14 | toilet==15	
replace toilet_mdg = 0 if (toilet<23 | toilet==31) & shared_toilet==1 		
replace toilet_mdg = . if  toilet==. | toilet==99
lab var toilet_mdg "Household has improved sanitation with MDG Standards"
tab toilet toilet_mdg, miss

	
*** Destitution MPI ***
/*Members of the household are considered deprived if household practises 
open defecation or uses other unidentifiable sanitation practises */
********************************************************************
gen	toilet_u = .
replace toilet_u = 0 if toilet==95 | toilet==96
replace toilet_u = 1 if toilet!=95 & toilet!=96 & toilet!=.
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

clonevar water = ws1  
clonevar timetowater = ws4  
clonevar ndwater = ws2 

*** Standard MPI ***
/* Members of the household are considered deprived if the household 
does not have access to improved drinking water (according to the SDG 
guideline) or safe drinking water is at least a 30-minute walk from 
home, roundtrip */
********************************************************************
codebook water, tab(99)
	
gen	water_mdg     = 1 if water<32  | water==41 | water==51 | water==91 	
replace water_mdg = 0 if water==32 | water==42 | water==61 | ///
						 water==71 | water==81 | water==96  

codebook timetowater, tab(999)		
replace water_mdg = 0 if water_mdg==1 & timetowater >= 30 & timetowater!=. & ///
						 timetowater!=998 & timetowater!=999	  	
replace water_mdg = . if water==. | water==99
lab var water_mdg "Household has drinking water with MDG standards (considering distance)"
tab water water_mdg, miss


*** Destitution MPI ***
/* Members of the household is identified as destitute if household 
does not have access to safe drinking water, or safe water is more 
than 45 minute walk from home, round trip.*/
********************************************************************
gen	water_u = .
replace water_u = 1 if water<32  | water==41 | water==51 | water==91 					   
replace water_u = 0 if water==32 | water==42 | water==61 | ///
					   water==71 | water==81 | water==96
					   
replace water_u = 0 if water_u==1 & timetowater>45 & timetowater!=. ///
					   & timetowater!=998 & timetowater!=999 	
					   
replace water_u = . if water==99 | water==.	
lab var water_u "Household has drinking water with MDG standards (45 minutes distance)"
tab water water_u, miss



********************************************************************************
*** Step 2.8 Housing ***
********************************************************************************

/* Members of the household are considered deprived if the household 
has a dirt, sand or dung floor */
clonevar floor = hc3
codebook floor, tab(99)
gen	floor_imp = 1
replace floor_imp = 0 if floor<=12 | floor==96 	
replace floor_imp = . if floor==99	
lab var floor_imp "Household has floor that it is not earth/sand/dung"
tab floor floor_imp, miss	


/* Members of the household are considered deprived if the household has walls 
made of natural or rudimentary materials. We followed the report's definitions
of natural or rudimentary materials. */
clonevar wall = hc5
codebook wall, tab(99)
gen	wall_imp = 1 
replace wall_imp = 0 if wall<=26 | wall==96 	
replace wall_imp = . if wall==99	
lab var wall_imp "Household has wall that it is not of low quality materials"
tab wall wall_imp, miss	

		
/* Members of the household are considered deprived if the household has roof 
made of natural or rudimentary materials. We followed the report's definitions
of natural and rudimentary materials. */
clonevar roof = hc4
codebook roof, tab(99)	
gen	roof_imp = 1 
replace roof_imp = 0 if roof<=24  | roof==96
replace roof_imp = . if roof==99 	
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


clonevar cookingfuel = hc6 

	
*** Standard MPI ***
/* Members of the household are considered deprived if the 
household uses solid fuels and solid biomass fuels for cooking. */
*****************************************************************
codebook cookingfuel hc6, tab(99)

gen	cooking_mdg = 1
replace cooking_mdg = 0 if cookingfuel>5 & cookingfuel<95 
replace cooking_mdg = . if cookingfuel==. |cookingfuel==99
lab var cooking_mdg "Household cooks with clean fuels"	 
tab cookingfuel cooking_mdg, miss		


*** Destitution MPI ***
*** (same as standard MPI) ***
****************************************	
gen	cooking_u = cooking_mdg
lab var cooking_u "Household cooks with clean fuels"


********************************************************************************
*** Step 2.10 Assets ownership ***
********************************************************************************

*** Television/LCD TV/plasma TV/color TV/black & white tv
lookfor tv television plasma lcd
codebook hc8c
clonevar television = hc8c 
lab var television "Household has television"

		
***	Radio/walkman/stereo/kindle
lookfor radio walkman stereo
codebook hc8b
clonevar radio = hc8b 
lab var radio "Household has radio"	


***	Handphone/telephone/iphone/mobilephone/ipod
lookfor telephone mobilephone ipod phone
codebook hc8d hc9b
clonevar telephone =  hc8d
replace telephone=1 if telephone!=1 & hc9b==1	
	//hc12=mobilephone. Combine information on telephone and mobilephone.	
tab hc8d hc9b if telephone==1,miss
lab var telephone "Household has telephone (landline/mobilephone)"	

	
***	Refrigerator/icebox/fridge
lookfor refrigerator 
codebook hc8e
clonevar refrigerator = hc8e 
lab var refrigerator "Household has refrigerator"


***	Car/van/lorry/truck
lookfor car voiture truck van
codebook hc9f
clonevar car = hc9f 
lab var car "Household has car"		

	
***	Bicycle/cycle rickshaw
lookfor bicycle bicyclette
codebook hc9c
clonevar bicycle = hc9c
lab var bicycle "Household has bicycle"	
	
	
***	Motorbike/motorized bike/autorickshaw
lookfor motorbike moto
codebook hc9d
clonevar motorbike = hc9d
lab var motorbike "Household has motorbike"

	
***	Computer/laptop/tablet: no data
lookfor computer ordinateur laptop ipad tablet
gen computer = .
lab var computer "Household has computer"


***	Animal cart
lookfor brouette charrette cart
codebook hc9e
gen animal_cart = hc9e
lab var animal_cart "Household has animal cart"	
 
 
foreach var in television radio telephone refrigerator car ///
			   bicycle motorbike computer animal_cart {
replace `var' = 0 if `var'==2 
label define lab_`var' 0"No" 1"Yes"
label values `var' lab_`var'			   
replace `var' = . if `var'==9 | `var'==99 | `var'==8 | `var'==98 
}
	//Labels defined and missing values replaced	
	
	

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



********************************************************************************
*** Step 2.11 Rename and keep variables for MPI calculation 
********************************************************************************
	
	//Retain data on sampling design: 
desc psu
clonevar strata = stratum
label var psu "Primary sampling unit"
label var strata "Sample strata"


	//Retain year, month & date of interview:
desc hh5y hh5m hh5d 
clonevar year_interview = hh5y 	
clonevar month_interview = hh5m 
clonevar date_interview = hh5d 

		
*** Rename key global MPI indicators for estimation ***
recode hh_mortality         (0=1)(1=0) , gen(d_cm)
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
recode hh_mortality         (0=1)(1=0) , gen(d_cm_01)
recode hh_nutrition_uw_st 	(0=1)(1=0) , gen(d_nutr_01)
recode hh_child_atten 		(0=1)(1=0) , gen(d_satt_01)
recode hh_years_edu6 		(0=1)(1=0) , gen(d_educ_01)
recode electricity 			(0=1)(1=0) , gen(d_elct_01)
recode water_mdg 			(0=1)(1=0) , gen(d_wtr_01)
recode toilet_mdg 			(0=1)(1=0) , gen(d_sani_01)
recode housing_1 			(0=1)(1=0) , gen(d_hsg_01)
recode cooking_mdg 			(0=1)(1=0) , gen(d_ckfl_01)
recode hh_assets2    		(0=1)(1=0) , gen(d_asst_01)	
	

recode hh_mortality_u       (0=1)(1=0) , gen(dst_cm_01)
recode hh_nutrition_uw_st_u (0=1)(1=0) , gen(dst_nutr_01)
recode hh_child_atten_u 	(0=1)(1=0) , gen(dst_satt_01)
recode hh_years_edu_u 		(0=1)(1=0) , gen(dst_educ_01)
recode electricity_u		(0=1)(1=0) , gen(dst_elct_01)
recode water_u	 			(0=1)(1=0) , gen(dst_wtr_01)
recode toilet_u 			(0=1)(1=0) , gen(dst_sani_01)
recode housing_u 			(0=1)(1=0) , gen(dst_hsg_01)
recode cooking_u			(0=1)(1=0) , gen(dst_ckfl_01)
recode hh_assets2_u   		(0=1)(1=0) , gen(dst_asst_01)


	/*In this survey, the harmonised 'region_01' variable is the 
	same as the standardised 'region' variable.*/	
clonevar region_01 = region 



*** Keep main variables require for MPI calculation ***
keep hh_id ind_id psu strata weight ///
area region region_01 agec4 agec2 headship ///
d_cm d_nutr d_satt d_educ d_elct d_wtr d_sani d_hsg d_ckfl d_asst /// 
d_cm_01 d_nutr_01 d_satt_01 d_educ_01 ///
d_elct_01 d_wtr_01 d_sani_01 d_hsg_01 d_ckfl_01 d_asst_01


order hh_id ind_id psu strata weight ///
area region region_01 agec4 agec2 headship ///
d_cm d_nutr d_satt d_educ d_elct d_wtr d_sani d_hsg d_ckfl d_asst ///
d_cm_01 d_nutr_01 d_satt_01 d_educ_01 ///
d_elct_01 d_wtr_01 d_sani_01 d_hsg_01 d_ckfl_01 d_asst_01


*** Generate coutry and survey details for estimation ***
char _dta[cty] "Afghanistan"
char _dta[ccty] "AFG"
char _dta[year] "2010-2011" 	
char _dta[survey] "MICS"
char _dta[ccnum] "004"
char _dta[type] "micro"


*** Sort, compress and save data for estimation ***
sort ind_id
compress
la da "Micro data for `_dta[ccty]' (`_dta[ccnum]') from `c(current_date)' (`c(current_time)')."
save "$path_out/afg_mics10-11.dta", replace 





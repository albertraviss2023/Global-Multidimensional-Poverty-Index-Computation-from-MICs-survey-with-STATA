/******************************************************************************
	Purpose: Estimating the Global Multi-dimensional Poverty Index (MPI). 
	Data input: The model datasets are found in MICS Afghanistan 2011. 
        This code estimates MPI for Single Country for Single year estimations.
        Authored by: Albert Lutakome
	Date Last Modified: August 29, 2023 by Albert Lutakome
        Credits to: Dr Nicolai Suppa,OPHI.

Notes/Instructions:
To run this code, the dataset for deprivations has to be loaded and the mpitb package
has to be installed and make sure to set survey design parameters accordingly. 
*******************************************************************************/
do "MPI_deprivation_computation_mics.do"

ssc install mpitb

***Step 1: Accessing the dataset and setting survy parameters. 
*******************************************************************
use "$path_out/afg_mics10-11.dta", clear
sum
svyset psu[pw=weight],strata(strata) singleunit(centered)

*** Step 2: Setting Indicators and deprivations 
********************************************************************
mpitb set, na(G_MPI) d1(d_cm , na(hl)) d2(d_satt d_educ, na(ed)) /// 
		d3(d_elct d_wtr d_sani d_hsg d_ckfl d_asst , name(ls)) de(pref. spec) 

*** Step 3: Estimation of single country MPI
mpitb est , name(G_MPI) meas(all) indmeas(all) aux(hd) klist(20 33 50) ///
       weight(equal) svy lfr(myresults, replace) over(region area) 

********************************************************************************

***Step 4: Results Exploration:
********************************************************************************
cwf myresults
d
/// creating results frame

tab measure loa // to see which measures are available for each level of analysis (loa)

li measure b se if inlist(measure,"M0","H","A") & loa == "nat" & k == 33 , noo

// inspect particular estimates and their standard errors

recode subg (0=0 "rural") (1=1 "urban") if loa == "area" , gen(area)
// (0 differences between subg and area)

lab var area area
// Creating (rural-urban) variable for each LOA to see disparities. 


tabdisp indicator measure area if inlist(measure,"hd","hdk") ///
        & !mi(area) & inlist(k,33,.) , cell(b)
		
********************************************************************************

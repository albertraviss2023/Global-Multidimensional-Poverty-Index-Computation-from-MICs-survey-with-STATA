Multidimensional-Poverty-Index-Computation-with-STATA
This goal of this project is to compute deprivation variables for the multi-dimensional poverty indices(MPI) and also help in the measurement of multi-dimensional poverty indices(MPI) at the national level and across specific regions of a particular country.

General instructions:
This Code Project provides the code to merge the relevant datasets, recode data, and compute deprivation indicators, in addition to the computation of multi-dimensional poverty indices(MPI). The code is organized into 2 .do files in the parent folder The first file is for the computation of deprivations and the second file is for the estimation of MPI Indices. The two files have to be run after the correct working directories have been set.

Main files:
The parent folder contains 2 Main .do script Files from which the user can run all the code at once (.do) to perform the computations. The user needs to set the paths in the data File files correctly.

Working with older surveys:
The indicators that are created using the MICS are subject to change over time. If the provided code is used to create indicators from older or newer surveys, it is possible the variable names have changed over time or are not available in the older survey. The user may need to check the dataset in use for the availability of the variables needed to be used in the code and may need to adjust for missing variables or rename variables accordingly. Some of the code files will generate the variables with missing values for old surveys if the survey does not have that variable.

Creating tables
Tabulation has been done using tabout package for STATA. This is a free package and can be installed as demonstrated in the code. 
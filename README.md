# README for Engbom and Moser (2022)




## Description

This package contains all replication materials for the results presented in Engbom and Moser (2022).




## Overview of codes

This repository contains the following directories:

1. ~/1 draft;
2. ~/2 empirics;
3. ~/3 model.

We describe each of these below.


###### ~/1 draft

Contains tex files for manuscript and online appendix.

Opening the tex files will allow a user to disambiguate the origin of any figure or table file.


Compiling:

1. ~1 draft/EIMW2022.tex compiles jointly the manuscript and appendix;
2. the manuscript were compiled using PDFLaTeX in WinEdt v10.3;
3. can be compiled immediately after download.

Also contains corresponding pdf files.


###### ~/2 empirics 

This directory contains the code for the empirical section of the paper (sections 2-4, as well as section 7.1).

The empirical part of this project is based on administrative, confidential data from the Brazilian Brazilian Ministry of Labour and Social Security (Ministério do Trabalho e Previdência, or MTP). The data and code to reproduce the results are available to the interested researcher for use on-site in Rio de Janeiro upon submitting a research proposal for approval to the MTP. As both the data and code are confidential, they cannot be released to researchers without approval.


###### ~/3 model

To check replication of all results in the paper, in MATLAB:
1. open ~/3 model/1 code/RUNME.m;
2. change options.Directory on line 26 to the main directory on your local computer where the replication package is stored;
3. hit execute.

This will create and populate the subfolders "all" in ~/3 model/3 tables and ~/3 model/4 graphs:

1. move all .tex files from ~/3 model/3 tables/all into ~/1 draft/_tables (replace all existing files);
2. move all .png files from ~/3 model/4 graphs/all into ~/1 draft/_figures (replace all existing files);
3. then compile EIMW2022.tex in ~/1 draft;
4. doing so will replicate the printed manuscript and appendices.

The input data directory ~/3 model/2 data/all contains:

1. vector of estimated parameters ("Estimates.mat");
2. model moments when changing one parameter at a time around the estimated value ("Jacobian.mat");
3. targeted moments from the confidential micro data ("Moments.out", "MomentsByDecile.out" and "MomentsByDecileFE.out");
4. empirical wage distribution in 1994-1998 ("wages_data_1994_1998.out").




## References

Engbom, Niklas & Christian Moser. "Earnings Inequality and the Minimum Wage: Evidence from Brazil," conditionally accepted at the American Economic Review, 2022.

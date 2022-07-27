%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
README file for Engbom and Moser (2022): “Earnings Inequality and the Minimum Wage: Evidence from Brazil”
- Authors: Niklas Engbom and Christian Moser
- Journal: American Economic Review
- Time stamp: July 26, 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


OVERVIEW
--------

--- This README file describes the replication package associated with Engbom and Moser (2022) and is structured as follows:
	--- Data availability and provenance statements
	--- Statement about rights
	--- License for data and codes
	--- Summary of availability
	--- Details on each data source
	--- Computational requirements
	--- Software requirements
	--- Controlled Randomness
	--- Memory and Runtime requirements
	--- Dataset list
	--- Replication code folder ~/1 cleaning
	--- Replication code folder ~/2 empirics
	--- Replication code folder ~/3 model
	--- Sources of figures and tables
	--- References
	--- Acknowledgements


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


DATA AVAILABILITY AND PROVENANCE STATEMENTS
-------------------------------------------

--- This paper involves the analysis of external data. The authors of Engbom and Moser (2022) are secondary data users (i.e., they did not generate the RAIS, PME, PNAD, or other data) for this project, so the provenance and data availability statement coincide.

--- The replication files are partly based on the following datasets:
	--- RAIS, administered by Ministério da Economia (2020)
	--- PNAD, administered by Instituto Brasileiro de Geografia e Estatística (2021)
	--- PME, administered by Instituto Brasileiro de Geografia e Estatística (2022)
	--- Labor force statistics from International Labour Organization (2022)
	--- Unemployment rates from Instituto de Pesquisa Econômica Aplicada (2020) and Instituto Brasileiro de Geografia e Estatística (2020)
	--- Informality rates from Instituto de Pesquisa Econômica Aplicada (2021) and Instituto Brasileiro de Geografia e Estatística (2019)
	--- Minimum wage time series from Instituto de Pesquisa Econômica Aplicada (2022)

--- The identified RAIS microdata containing both worker and employer identifiers are confidential and cannot be shared as part of this replication package, but can be obtained upon submitting an application for data access to the Brazilian Ministry of the Economy (Ministério da Economia, or ME) via the Secretaria de Trabalho / Subsecretaria de Políticas Públicas de Trabalho / Coordenação-Geral de Cadastros, Identificação Profissional e Estudos / Coordenação de Estatísticas e Estudos do Trabalho (email: observatoriotrabalho@mte.gov.br, phone: +55 61 2031-6991). The application for data access should contain:
	--- The authors’ names, titles, affiliations, and contact details
	--- A short description of the research project
	--- A justification for why the identified microdata with time-consistent person and employer IDs is necessary
	--- The name, title, affiliation, and contact details of a person designated by the lead author’s host institution who is in charge of signing legal agreements, as will be required by the Brazilian ministry tasked with executing data agreements.

--- Neither any particular nationality is required nor is there any cost associated with applying for the confidential RAIS data. However, it can take some months to negotiate data use agreements and gain access to the data.

--- The PNAD microdata can be downloaded directly from IBGE at https://www.ibge.gov.br/estatisticas/sociais/populacao/9127-pesquisa-nacional-por-amostra-de-domicilios.html?=&t=downloads or https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/ and cleaning procedures are made available from Data Zoom, an initiative by PUC-Rio, at http://www.econ.puc-rio.br/datazoom/english/pnad.html.

--- The PME microdata can be downloaded directly from IBGE at https://www.ibge.gov.br/estatisticas/sociais/trabalho/9180-pesquisa-mensal-de-emprego.html?=&t=downloads or https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Mensal_de_Emprego/Microdados/ and cleaning procedures are made available from Data Zoom, an initiative by PUC-Rio, at http://www.econ.puc-rio.br/datazoom/english/pme.html.

--- All other data can be accessed via the links provided in the “References” section below.

--- The parts of the codes that use PNAD and PME can be run in the absence of RAIS data, although the current code files often contain a mix of code using PNAD/PME and code using RAIS, so only the relevant parts of the code files should be run.

--- The authors of the current paper will assist with any reasonable replication attempts for two years following publication.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


STATEMENT ABOUT RIGHTS
----------------------

--- We certify that the authors of the manuscript have legitimate access to and permission to use the data used in this manuscript.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


LICENSE FOR DATA AND CODE
-------------------------

--- All data produced by the authors as well as all code is licensed under an MIT License. See LICENSE.txt for details.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SUMMARY OF AVAILABILITY
-----------------------

--- Some data cannot be made publicly available.

--- To be precise, while some data (PME, PNAD, macroeconomic time series, etc.) are publicly available, some other data (RAIS) are confidential and cannot be made publicly available.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


DETAILS ON EACH DATA SOURCE
---------------------------

--- The raw data files for RAIS come in compressed .7Z format. Once extracted, the raw data files are in .TXT format and can be read with any (open-source or proprietary) software. As part of this replication package, all raw data files in .TXT format are read and then saved in Stata-native .DTA format. The replication package also contains a data dictionary in English, which is used to name and label all variables.

--- The raw data files for PNAD and PME come in .TXT format. As part of this replication package, all raw data files in .TXT format are read using the Data Zoom package and then saved in Stata-native .DTA format. The replication package also contains a data dictionary in English, which is used to name and label all variables.

--- All other data used for this project come in .XLS or .XLSX format to be opened using Microsoft Office Excel, in .CSV format to be opened using any text editor (e.g., TextEdit on macOS), in .PDF format to be opened using any PDF viewer (e.g., Preview on macOS), or in .DTA format to be opened using Stata.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


DATASET LIST
------------

--- Datasets used in folder ~/1 cleaning:
	--- RAIS from Ministério da Economia (2020): confidential and not provided as part of this replication package.
	--- Consumer price indices from IPEA: public and provided as part of this replication package. The relevant consumer price index time series are included as part of the replication package and stored in the subsubfolder “cpi” inside the subfolder “_inputs” inside the replication package folder “1 cleaning”.
	--- GDP from International Monetary Fund: public and provided as part of this replication package. The relevant GDP time series are included as part of the replication package and stored in the subsubfolder “gdp” inside the subfolder “_inputs” inside the replication package folder “1 cleaning”.
	--- Minimum comparable areas crosswalk from Ehrl (2017): public and provided as part of this replication package. The resulting crosswalks are included as part of the replication package and stored in the subsubfolder “geography” inside the subfolder “_inputs” inside the replication package folder “1 cleaning”.
	--- Geographic (i.e., state/municipality/microregion/mesoregion) crosswalks based on RAIS from Ministério da Economia (2020): deidentified information based on confidential data that is provided as part of this replication package. The resulting crosswalks are included as part of the replication package and stored in the subsubfolder “geography” inside the subfolder “_inputs” inside the replication package folder “1 cleaning”.
	--- Industry crosswalks based on RAIS from Ministério da Economia (2020): deidentified information based on confidential data that is provided as part of this replication package. The resulting crosswalks are included as part of the replication package and stored in the subsubfolder “industry” inside the subfolder “_inputs” inside the replication package folder “1 cleaning”.
	--- Occupation crosswalks based on RAIS from Ministério da Economia (2020): deidentified information based on confidential data that is provided as part of this replication package. The resulting crosswalks are included as part of the replication package and stored in the subsubfolder “occupation” inside the subfolder “_inputs” inside the replication package folder “1 cleaning”.
	--- National minimum wage from Instituto de Pesquisa Econômica Aplicada (2022): public and provided as part of this replication package. The relevant minimum wage time series are included as part of the replication package and stored in the subsubfolder “min_wage” inside the subfolder “_inputs” inside the replication package folder “1 cleaning”.
 
--- Datasets used in folder ~/2 empirics:
	--- RAIS from Ministério da Economia (2020): confidential and not provided as part of this replication package.
	--- Consumer price indices from IPEA: public and provided as part of this replication package. The relevant consumer price index time series are included as part of the replication package and stored in the subsubfolder “cpi” inside the subfolder “_inputs” inside the replication package folder “2 empirics”.
	--- GDP from International Monetary Fund: public and provided as part of this replication package. The relevant GDP time series are included as part of the replication package and stored in the subsubfolder “gdp” inside the subfolder “_inputs” inside the replication package folder “2 empirics”.
	--- National minimum wage from Instituto de Pesquisa Econômica Aplicada (2022): public and provided as part of this replication package. The relevant minimum wage time series are included as part of the replication package and stored in the subsubfolder “min_wage” inside the subfolder “_inputs” inside the replication package folder “2 empirics”.
	--- Other labor market statistics (labor force size, unemployment rate, and informality rate) from various sources: public and provided as part of this replication package. The relevant labor market statistics are included as part of the replication package and stored in the subsubfolder “other” inside the subfolder “_inputs” inside the replication package folder “2 empirics”.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


COMPUTATIONAL REQUIREMENTS
--------------------------

--- The empirical analysis (i.e., all Stata code) was run on a server with Debian GNU/Linux 10 (buster) with 1024GB RAM, a 1.5TB disk, and 32 cores.

--- The structural-model analysis (i.e., all MATLAB code) was run on a standard laptop computer (2017 MacBook Pro) with 16GB RAM and 2.8GHz Quad-Core Intel processor.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SOFTWARE REQUIREMENTS
---------------------

--- Software and required packages include the following:
	--- Stata/MP version 16.0
		--- moremata (https://ideas.repec.org/c/boc/bocode/s455001.html, as of February 19, 2022)
		--- ftools (https://github.com/sergiocorreia/ftools, as of May 6, 2022)
		--- reghdfe (https://github.com/sergiocorreia/reghdfe/, as of November 27, 2021)
		--- ivreg2 (https://ideas.repec.org/c/boc/bocode/s425401.html, as of May 10, 2022)
		--- ivreghdfe (https://github.com/sergiocorreia/ivreghdfe, as of ​​December 25, 2021)
		--- gtools (https://github.com/mcaceresb/stata-gtools, as of March 5, 2022)
		--- carryforward (https://ideas.repec.org/c/boc/bocode/s444902.html, as of February 12, 2016)
		--- datazoom_social (https://github.com/datazoompuc/datazoom_social_Stata, as of July 25, 2022)
		--- datazoom_pme (https://github.com/datazoompuc/datazoom_social_Stata/tree/main/PME, as of March 18, 2022)
		--- datazoom_pnad (https://github.com/datazoompuc/datazoom_social_Stata/tree/main/PNAD, as of July 12, 2022)
		--- All required Stata packages are included as part of the replication package in a subfolder “_packages”
	--- MATLAB R2021b Update 1 (9.11.0.1809720) 64-bit (glnxa64)
		--- Optimization toolbox (as of November 12, 2021)
		--- Symbolic Math toolbox (as of November 12, 2021)
		--- Statistics and Machine Learning toolbox (as of November 12, 2021)
		--- Parallel Computing toolbox (as of November 12, 2021)
		--- The required MATLAB packages are not included as part of the replication package but can be obtained as part of the standard MATLAB installation.

--- Portions of the code use bash or zsh scripting, which may require Linux. The exact versions used are GNU bash, version 5.0.3(1)-release (x86_64-pc-linux-gnu) or zsh 5.7.1 (x86_64-debian-linux-gnu).

--- Parts of the code call MATLAB from within Stata, which can cause difficulties with execution and difficulties with instructions for the code to wait for results of the call under alternative operating systems.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


CONTROLLED RANDOMNESS
---------------------

--- The master code file “0_MASTER.do” in the folder ~/1 cleaning uses the command -set seed 1- in order to set a specific value for the random-number seed in Stata. This seed ensures that any ambiguity in sorts is resolved.

--- The master code file “EIMW_0_MASTER.do” in the folder ~/2 empirics uses the command -set seed 1- in order to set a specific value for the random-number seed in Stata. This seed ensures that any ambiguity in sorts is resolved.

--- The simulation code file “Simulate.m” in the folder ~/3 model/1 code uses the command -rng(1)- in order to set a specific value for the random-number seed in MATLAB. This seed ensures that the simulated data are replicable based on a deterministic starting point for the simulations.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


MEMORY AND RUNTIME REQUIREMENTS
-------------------------------

--- Memory requirement is up to close to 1024GB RAM at peak load. Storage disk space of at least 1.5TB is recommended.

--- Runtime is approximately 48 days of highly parallelized jobs submitted to the server node with computational capacity described above.
	--- Some of the parts of the code, for example the code “1_READ.do” contained in the folder ~/1 cleaning, can be further parallelized by submitting multiple jobs, each reading a separate year of the data from 1985-2018. However, the final cleaning procedure “2_CLEAN.do” must be submitted in a single, large job for all years 1985-2018 jointly since that procedure uses information from all years to clean certain aspects of the data such as imputing individuals’ year of birth, etc. Note that this joint cleaning procedure requires a large amount of RAM and computational time because it loads data from all years 1985-2018 in order to make the data consistent across years.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


REPLICATION CODE FOLDER ~/1 CLEANING
------------------------------------

--- Contains Stata .do files that read the raw RAIS data and produce a set of cleaned data files separately for each year 1985-2018.

--- The list of included files is as follows:
	--- 0_MASTER.do: Master file that runs all other files.
	--- 1_READ.do: Reads the raw RAIS data by calling a sequence of other files and saves read files.
		--- 1A_READ_UNZIP.do: Unzips the compressed raw data.
		--- 1B_READ_ACCENTS.do: Converts accents into readable format.
		--- 1C_READ_RENAME.do: Renames key variables.
		--- 1D_READ_DESTRING.do: Destrings variables appropriately.
		--- 1E_READ_LABEL.do: Labels key variables.
	--- 2_CLEAN.do: Cleans data based on the complete set of read files for 1985-2018.

--- The final output from this procedure is a set of files “clean1985.dta”, “clean1986.dta”, ..., “clean2018.dta”, each of which contain the cleaned RAIS data for a given year in the range 1985-2018. These files are required in order to run the empirical analysis that follows and that is presented in the paper.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


REPLICATION CODE FOLDER ~/2 EMPIRICS
------------------------------------

--- This directory contains the code for the empirical section of the paper (sections 2-4, section 7.1, and Appendices A-B).

--- The empirical part of this project is based on administrative, confidential data from the ME. All codes, including those used to clean and analyze the data, are shared as part of this replication package. The original microdata on which these codes were run cannot be shared as part of this replication package but are available to the interested researcher for local storage and use for research purposes upon submitting a research proposal for approval to the ME---see details above!

--- The list of included files is as follows:
	--- EIMW_0_MASTER.do: Master file that sets parameters and calls all subsequent files.
	--- EIMW_1_AUXILIARY_DATA.do: Constructs auxiliary datasets such as the time series of Brazil’s nominal and real minimum wage over the period of study.
	--- EIMW_2_EST_BASELINE.do: Construct baseline data based on RAIS data.
	--- EIMW_3_EST_MONTHLY.do: Construct full monthly panel data based on RAIS data.
	--- EIMW_4_EST_FSIZE.do: Compute employer size distribution.
	--- EIMW_5_EST_AKM.do: Find largest connected sets and estimates AKM wage equations.
	--- EIMW_6_EST_PNAD.do: Compute moments for estimation based on the PNAD survey data.
	--- EIMW_7_EST_COMB.do: Construct moments for model estimation.
	--- EIMW_8_SUMMARY_STATS.do: Computes summary statistics.
	--- EIMW_9_PERCENTILES.do: Compute log earnings percentiles.
	--- EIMW_10_MOTIVATING_FACTS.do: Generate a set of motivating facts.
	--- EIMW_11_MW_SPIKE.do: Estimate minimum-wage spike in raw earnings distribution.
	--- EIMW_12_LEE.do: Estimate Lee (1999) and Autor, Manning, and Smith (2016) regressions.
	--- EIMW_13_LEE_PNAD_PME.do: Analyze earnings and employment in cross-sectional PNAD and longitudinal PME household survey data.
	--- EIMW_14_COMPARATIVE_STATICS.do: Investigate comparative statics in the data.
	--- EIMW_15_MODEL_RESULTS.do: Process model results.
	--- FUN_AKM_KSS.m: Estimates KSS correction to AKM variance decomposition.
	--- FUN_AKM.do: Prepares data, calls MATLAB file FUN_AKM.m to run the two-way fixed effects (AKM) estimation estimation, and processes output.
	--- FUN_AKM.m: Estimates worker fixed effects, employer fixed effects, time fixed effects, returns to demographics, and additional controls based on Abowd, Kramarz, and Margolis (1999) using the algorithm by Card, Heining, and Kline (2013).
	--- FUN_CONNECTED.do: Prepares data, calls MATLAB file FUN_CONNECTED.m to find the largest connected set, and saves data merged with the largest connected set.
	--- FUN_CONNECTED.m: Finds the (weakly or strongly) connected set of employers.
	--- FUN_EXTENSION.do: Function to define time stamp file name extension.
	--- FUN_LOAD.do: Function to load data in a consistent manner.
	--- FUN_PROGRAMS.do: Function to load user-written programs.
	--- LeaveOutTwoWay-3.02: Folder containing codes that implement a modified version of the leave-one-out estimator developed by Kline, Saggio, and Sølvsten (2020), with modifications made to the original codes that are publicly available through those authors.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


REPLICATION CODE FOLDER ~/3 MODEL
---------------------------------

--- To replicate all structural-model-based results in the paper (sections 6-7 and Appendices D-E), please adhere to the following instructions.

--- Download the folder ~/3 model to a local directory of choice.
--- Please note that the entire folder ~/3 model must be downloaded in order for the code to run-––it is not, for instance, sufficient to only download ~/3 model/1 code.

--- The list of included code files (~/3 model/1 code) is as follows:
	--- RUNME.m: Master file that runs all other files.
	--- CheckReservationWage.m: Checks that workers prefer to work over unemployment at the lowest grid point under the new minimum wage.
	--- ComputeMoments.m: Computes a moments based on simulated model data.
	--- ConstructSobol.m: Constructs a sobol sequence to draw potential parameter vectors for estimation.
	--- csv2mat_block.m: Reads .csv files to MATLAB.
	--- csv2mat_numeric.m: Reads .csv files to MATLAB.
	--- DiffEq.m: Solves the system of differential equations C.5-C.6 in the paper.
	--- ExogenousParameters.m: Defines externally set parameters.
	--- FindFlowValue.m: Ex post computes the flow value of leisure consistent with the reservation wage.
	--- GetDerivative.m: Gets the derivative of the wage policy and the pdf of the offer distribution.
	--- Graphs.m: Graphs output.
	--- Grids.m: Constructs numerical grids.
	--- LoadTargets.m: Defines targeted moments in estimation.
	--- NumericalApproximations.m: Defines numerical settings.
	--- parassign.m: Circumvents bug in parfor loop.
	--- ReadData.m: Loads empirical moments for estimation.
	--- Simulate.m: Simulates the model based on solution.
	--- Solve.m: Solves the model for a given parameter vector.
	--- SolveForCost.m: Finds the vacancy cost consistent with empirical worker mobility rates for estimation.
	--- SolveForFlows.m: Solves for equilibrium flows consistent with vacancy cost for counterfactual exercises.

--- The list of included data files (~/3 model/2 data/all and ~/3 model/2 data/young) is as follows:
	--- Estimates.mat: Vector of estimated parameters.
	--- Jacobian.mat: Implied minimum distance when changing one parameter at a time around the estimated value.
	--- Moments.out: Targeted aggregate moments from the confidential micro data.
	--- MomentsByDecile.out: Targeted moments by AKM person FE decile from the confidential micro data.
	--- MomentsByDecileFE.out: Targeted moments by AKM firm FE decile from the confidential micro data.
	--- wages_data_1994_1998.out: Binned empirical wage distribution in 1994-1998 for wage density plot.
	--- Please note that the files “Estimates.mat” and “Jacobian.mat” are produced by running the first part of the provided structural model for a large number of potential parameter draws, and recording the results. Although we do not provide the code to do this, a user could replicate it by looping over the first part of the provided code for a wide range of potential parameter draws (or alternatively reach out to us so we can share the necessary code). Please note, however, that this is highly computationally intensive, with decent precision requiring several days of computational time on high-performance computer clusters with over 1000 cores. It is not feasible to replicate this part in a reasonable time frame on a regular desktop computer.

--- Open ~/3 model/1 code/RUNME.m
	--- Set options.Age=“all” on line 33––this reproduces all structural-model-based results in the paper apart from Tables D.1 and E.2.
--- Set options.Age=“young” on line 33––this reproduces Table E2.
--- In order to reproduce Table D.1, a user first has to run RUNME.m with options.Age=“all” on line 33 and options.StoreSimulation=”yes” on line 40. This will store a simulated data set, ~/3 model/2 data/all/Model_microdata.csv, for analysis in Stata. To reproduce Table D.1 then requires running Stata file EIMW_15_MODEL_RESULTS.do lines 120-190 (after completing RUNME.m).

--- Hit execute and accept to “change folder”
--- Please note that the user must accept to “change folder” or MATLAB will not be able to find the necessary data files.
--- All figures and tables in the structural-model part of the paper and appendices are created in .pdf and .tex format, respectively, and stored in ~/3 model/3 tables and ~/3 model/4 graphs.
--- Setting the variable options.Age=”all” on line 33 reproduces all structural-model-based tables and figures in the paper apart from Appendix Tables D.1 and E.2.
--- To also reproduce Table D.1 requires running the code once with setting options.Age=”all” on line 33 and options.StoreSimulation=”yes” on line 40. Then the user has to run the Stata code EIMW_15_MODEL_RESULTS.do lines 120-190.
--- To also reproduce Table E.2 requires running the code once with setting options.Age=”young” on line 33.

--- The minimum distance estimation of the structural model is done by running the first part of the provided code for a very large number of potential parameter draws (based on sobol sequences) on a high-capacity computer cluster, and recording a set of moments. 
	--- We have only provided the estimates and derivatives of the objective function from this procedure, which the user may use to study identification. 
	--- The actual implementation of this routine requires several days of computational time on over 1000 cores running in parallel. 
	--- Given the substantial computational resources required to replicate this exercise, this code is not provided as part of this replication package but the authors are happy to provide it to any interested user upon request.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SOURCES OF FIGURES AND TABLES
-----------------------------

--- The replication package is designed to reproduce all figures and tables that appear in the paper. However, in order to reproduce figures and tables in practice, the confidential data from RAIS is required, as well as the publicly available data from PME and PNAD. None of these three datasets are included as part of the current replication package. Therefore, the codes that are included as part of this replication package will not produce any output. However, the interested researcher may obtain access to the confidential RAIS data and download the publicly available PME and PNAD data following the instructions provided as part of this replication package.

--- In addition to the list of references to all figures and tables provided below, all Stata and MATLAB code files mark the exact locations where figures are produced with “*** PAPER X #” or  “*** APPENDIX X #”, where “X” stands in for “TABLE” or “FIGURE” and “#” stands in for the number of the figure or table (e.g., “*** PAPER FIGURE 11” or “*** APPENDIX TABLE B.3”).

--- The following contains a list of all figures that appear in the paper, and which exact line of which Stata or MATLAB code file reproduces them:
	--- Figure 1: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 401 (panels A and B) and line 258 (panel C)
	--- Figure 2: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 239
	--- Figure 3: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 676 (panel A), line 692 (panel B), and line 700 (panel C)
	--- Figure 4: Stata code “EIMW_12_LEE.do” line 700 (panels A and B)
	--- Figure 5: MATLAB code “RUNME.m” line 224
	--- Figure 6: MATLAB code “RUNME.m” line 285
	--- Figure 7: MATLAB code “RUNME.m” line 373
	--- Figure 8: Stata code “EIMW_12_LEE.do” line 890 (panels A and B)
	--- Figure 9: MATLAB code “RUNME.m” line 668
	--- Figure 10: MATLAB code “RUNME.m” line 900
	--- Figure 11: MATLAB code “RUNME.m” line 1031
	--- Figure 12: MATLAB code “RUNME.m” line 1417
	--- Figure A.1: Stata code “EIMW_8_SUMMARY_STATS.do” line 190 (panels A and B)
	--- Figure A.2: Stata code “EIMW_8_SUMMARY_STATS.do” line 199 (panels A and B)
	--- Figure B.1: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 229
	--- Figure B.2: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 342 (panel A) and line 331 (panel B)
	--- Figure B.3: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 351 (panels A and B)
	--- Figure B.4: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 430 (panels A and B)
	--- Figure B.5: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 440 (panels A and B)
	--- Figure B.6: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 1055
	--- Figure B.7: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 952
	--- Figure B.8: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 960
	--- Figure B.9: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 1002 (panel A), line 981 (panel B), and line 1024 (panel C)
	--- Figure B.10: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 666 (panels A and B)
	--- Figure B.11: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 767 (panels A and B) and line 781 (panels C and D)
	--- Figure B.12: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 740
	--- Figure B.13: Stata code “EIMW_12_LEE.do” line 730 (panels A and B)
	--- Figure B.14: Stata code “EIMW_12_LEE.do” line 765 (panels A and B)
	--- Figure B.15: Stata code “EIMW_12_LEE.do” line 862 (panels A and B)
	--- Figure B.16: Stata code “EIMW_12_LEE.do” line 790 (panels A and B)
	--- Figure B.17: Stata code “EIMW_12_LEE.do” line 815 (panels A and B)
	--- Figure B.18: Stata code “EIMW_12_LEE.do” line 996 (panels A and B)
	--- Figure B.19: Stata code “EIMW_12_LEE.do” line 1071 (panels A and B)
	--- Figure B.20: Stata code “EIMW_12_LEE.do” line 1097 (panels A and B)
	--- Figure B.21: Stata code “EIMW_12_LEE.do” line 1123 (panels A and B)
	--- Figure B.22: Stata code “EIMW_12_LEE.do” line 1149 (panels A and B)
	--- Figure B.23: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 1450 (panel A) and line 1459 (panel B)
	--- Figure B.24: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 1224 (panels A and B)
	--- Figure B.25: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 1248 (panel A) and line 1257 (panel B)
	--- Figure D.1: MATLAB code “RUNME.m” line 451
	--- Figure D.2: MATLAB code “RUNME.m” line 472
	--- Figure D.3: MATLAB code “RUNME.m” line 519
	--- Figure D.4: MATLAB code “RUNME.m” line 1526
	--- Figure D.5: MATLAB code “RUNME.m” line 1650
	--- Figure D.6: MATLAB code “RUNME.m” line 1770
	--- Figure D.7: MATLAB code “RUNME.m” line 1893
	--- Figure D.8: MATLAB code “RUNME.m” line 562
	--- Figure E.1: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 960
	--- Figure E.2: MATLAB code “RUNME.m” line 1154
	--- Figure E.3: MATLAB code “RUNME.m” line 1270
	--- Figure E.4: MATLAB code “RUNME.m” line 2001
	--- Figure E.5: MATLAB code “RUNME.m” line 2106
	--- Figure E.6: MATLAB code “RUNME.m” line 2194
	--- Figure E.7: MATLAB code “RUNME.m” line 2283
	--- Figure E.8: MATLAB code “RUNME.m” line 2367
	--- Figure E.9: MATLAB code “RUNME.m” line 2456

--- The following contains a list of all tables that appear in the paper, and which exact line of which (Stata or MATLAB) code file reproduces them:
	--- Table 1: Stata code “EIMW_8_SUMMARY_STATS.do” line 150 (panel A), Stata code “EIMW_13_LEE_PNAD_PME.do” line 1008 (panel B) and line 1552 (panel C)
	--- Table 2: Stata code “EIMW_5_EST_AKM.do” line 15 (calls Stata code “FUN_AKM.do”, which produces table output in line 248 by calling MATLAB code “FUN_AKM.m” and in line 431 by calling MATLAB code “FUN_AKM_KSS.m”)
	--- Table 3: Stata code “EIMW_13_LEE_PNAD_PME.do” line 1865 (panels A and B) and Stata code “EIMW_12_LEE.do” line 530 (panel C, row 1), line 531 (panel C, row 2), and line 533 (panel C, row 3).
	--- Table 4: MATLAB code “RUNME.m” line 143
	--- Table 5: Stata code “EIMW_7_EST_COMB.do” line 1012 (data columns 1, 3, and 5) and MATLAB code “RUNME.m” line 765
	--- Table 6: MATLAB code “RUNME.m” line 788
	--- Table 7: MATLAB code “RUNME.m” line 966
	--- Table A.1: Stata code “EIMW_13_LEE_PNAD_PME.do” line 1008
	--- Table A.2: Stata code “EIMW_13_LEE_PNAD_PME.do” line 1552
	--- Table A.3: See labor force statistics from ILO (https://api.worldbank.org/v2/en/indicator/SL.TLF.TOTL.IN?downloadformat=csv), unemployment rates from IPEA	 and IBGE (http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=486696880 and https://www.ibge.gov.br/estatisticas/sociais/trabalho/9173-pesquisa-nacional-por-amostra-de-domicilios-continua-trimestral.html?=&t=series-historicas&utm_source=landing&utm_medium=explica&utm_campaign=desemprego), and informality rates from IPEA and IBGE (ttp://www.ipeadata.gov.br/ExibeSerie.aspx?serid=486696835&module=M and https://agenciadenoticias.ibge.gov.br/media/com_mediaibge/arquivos/340b85de6df90790f569e157ed090188.pdf). All of these source data files are included in a folder “other” as part of this replication package. The resulting number for total formal employment are 68225692*(1-.076)*(1-.578) = 26603107.630176 for 1996 and 102,576,163*(1-.117)*(1-.411) = 53,348,528.886181 for 2018 (panel A) and Stata code “EIMW_8_SUMMARY_STATS.do” line 150 (panel B)
	--- Table A.4: Stata code “EIMW_10_MOTIVATING_FACTS.do” lines 1550-1552
	--- Table B.1: Stata code “EIMW_10_MOTIVATING_FACTS.do” line 122
	--- Table B.2: Stata code “EIMW_10_MOTIVATING_FACTS.do” lines 1465-1497
	--- Table D.1: Stata code “EIMW_15_MODEL_RESULTS.do” lines 120-190, simulated data based on the structural model after complete run of MATLAB code “RUNME.m”
	--- Table E.1: Stata code “EIMW_5_EST_AKM.do” line 15 (calls Stata code “FUN_AKM.do”, which produces table output in line 248 by calling MATLAB code “FUN_AKM.m”) and MATLAB code “RUNME.m” line 1131
	--- Table E.2: Stata code “EIMW_7_EST_COMB.do” with setting global age_min = 18 and global age_max = 36 in master file “EIMW_0_MASTER.do”, line 1012 (data columns 1, 3, and 5), MATLAB code “RUNME.m” with setting options.Age=”young”, line 766 (model columns 2, 4, and 6)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


REFERENCES
----------

--- Abowd, John M, Francis Kramarz, and David N Margolis, “High Wage Workers and High Wage Firms,” Econometrica, 1999, 67 (2), 251–333.

--- Autor, David H., Alan Manning, and Christopher L. Smith, “The Contribution of the Minimum Wage to US Wage Inequality over Three Decades: A Reassessment,” American Economic Journal: Applied Economics, 2016, 8 (1), 58–99.

--- Card, David, Jörg Heining, and Patrick Kline, “Workplace Heterogeneity and the Rise of West German Wage Inequality,” Quarterly Journal of Economics, 2013, 128 (3), 967–1015.

--- Ehrl, Philipp, “Minimum Comparable Areas for the Period 1872-2010: An Aggregation of Brazilian Municipalities,” Estudos Econômicos, 2017, 47(1), 215-229.

--- Engbom, Niklas and Christian Moser, “Earnings Inequality and the Minimum Wage: Evidence from Brazil,” conditionally accepted (pending approval of the replication package) at the American Economic Review, 2022.

--- Instituto Brasileiro de Geografia e Estatística, “Pesquisa Nacional por Amostra de Domicílios (PNAD) Contínua,” Accessed from https://www.ibge.gov.br/estatisticas/sociais/populacao/9127-pesquisa-nacional-por-amostra-de-domicilios.html?=&t=downloads on December 31, 2019.

--- Instituto Brasileiro de Geografia e Estatística, “Pesquisa Mensal de Emprego, 2002-2012,” Accessed from https://www.ibge.gov.br/estatisticas/sociais/trabalho/9180-pesquisa-mensal-de-emprego.html?=&t=downloads on December 31, 2020.

--- Instituto Brasileiro de Geografia e Estatística, “PNAD Contínua - Pesquisa Nacional por Amostra de Domicílios Contínua: Séries Históricas, Taxa de Desocupação, Jan-Fev-Mar 2012 - Mar-Abr-Mai 2022,” Accessed from https://www.ibge.gov.br/estatisticas/sociais/trabalho/9173-pesquisa-nacional-por-amostra-de-domicilios-continua-trimestral.html?=&t=series-historicas&utm_source=landing&utm_medium=explica&utm_campaign=desemprego on December 31, 2021.

--- Instituto Brasileiro de Geografia e Estatística, “Pesquisa Nacional por Amostra de Domicílios Contínua: Indicadores Mensais Produzidos com Informações do Trimestre Móvel Terminado em Setembro de 2019,” Accessed from https://agenciadenoticias.ibge.gov.br/media/com_mediaibge/arquivos/340b85de6df90790f569e157ed090188.pdf on July 22, 2022.

--- Instituto de Pesquisa Econômica Aplicada, “Taxa de desemprego,” Accessed from http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=486696880 on December 31, 2020.

--- Instituto de Pesquisa Econômica Aplicada, “Grau de informalidade - definição I,” Accessed from http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=486696835&module=M on December 31, 2021.

--- Instituto de Pesquisa Econômica Aplicada, “Salário Mínimo Vigente, 1985-2018,” Accessed from http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=1739471028 on July 22, 2022.

--- International Labour Organization, “World Development Indicators: Labor Force, Total,” Accessed from https://api.worldbank.org/v2/en/indicator/SL.TLF.TOTL.IN?downloadformat=csv on July 22, 2022.

--- Kline, Patrick, Raffaele Saggio, and Mikkel Sølvsten, “Leave-Out Estimation of Variance Components,” Econometrica, 2020, 88 (5), 1859–1898, Available at https://doi.org/10.3982/ECTA16410.

--- Lee, David S., “Wage Inequality in The United States During The 1980s: Rising Dispersion Or Falling Minimum Wage?,” Quarterly Journal of Economics, 1999, 114 (3), 977–1023.

--- Ministério da Economia, “Relatório Anual de Informações Sociais (RAIS), 1985-2018,” Access granted to affiliates of Columbia University on January 23, 2020.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


ACKNOWLEDGEMENTS
----------------

--- This project uses the Stata cleaning routines for PNAD and PME microdata that were generously made public by Data Zoom. Data Zoom was developed by the Department of Economics at PUC-Rio with support from FINEP. Access to Data Zoom is free and open and available online at http://www.econ.puc-rio.br/datazoom/english/index.html.

--- This project builds on the leave-one-out estimation routines developed by Kline, Saggio, and Sølvsten (2020). The routines are available from the GitHub repository https://github.com/rsaggio87/LeaveOutTwoWay. Modified versions of this repository are included as part of the current replication package.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Title: The Impact of Coupons on the Visit-to-Purchase Funnel
Authors: Arun Gopalakrishnan (agopala@rice.edu) and Young-Hoon Park (yp34@cornell.edu)

*****README.TXT*****
This file summarizes the content of a zipped file that contains a simulated data set (simuldata.xlsx),containing variables akin to the ones reported in our paper. In addition, we provide the code (in the SAS language) in code.sas to analyze this data set, and also provide in a separate file (sas_output.xlsx) the tables that would result from running
this simulated data set using the SAS code, arranged similarly to the tables reported in
the paper. 

SIMULDATA.XLSX

There are seven variables in this file (which is individual-level data with each row representing one individual):
Group - a code for which experimental condition this participant belonged to. T1L is base coupon to the low-value segment; T1H is base coupon to the high-value segment; T2H is better coupon to the high-value segment; CGL is control group for the low-value segment and CGH is control group for the high-value segment.
Amount - Purchase amount in USD (net of any discount)
Purchase - A dummy for whether the consumer made a purchase (=1 if purchased).
Redeem - A dummy for whether the consumer redeemed the focal coupon (=1 if redeemed).
Pageviews - Number of pages viewed during browsing session.
Visit - A dummy for whether the consumer visited the website (=1 if visited).
Discount - percentage discount off the gross price that resulted in the Amount paid which is in the first column.

CODE.SAS

In the first line of the SAS code file, please replace the working directory in which simuldata.xlsx is to be found with the right path in place of "C:\Users\". 
PROC IMPORT OUT= WORK.temp DATAFILE= 			"C:\Users\simuldata.xlsx"
The remainder of the code should run in SAS producing a set of tables analogous to the ones found in our paper.

SAS_OUTPUT.XLSX

We show summary statistics for measures analogous to the ones we report in the paper in Tables 2a, 2b, 3a, and 3b. The statistics are grouped by the code for which experimental condition this participant belonged to. T1L is base coupon to the low-value segment; T1H is base coupon to the high-value segment; T2H is better coupon to the high-value segment; CGL is control group for the low-value segment and CGH is control group for the high-value segment. Please refer to the paper for further description of each measure.


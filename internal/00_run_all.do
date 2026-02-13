/********************************
  Spatial Mismatch Replication
********************************/

// Comments below indicate programs that differ between the disclosed package and that
// on the RDC system, largely because specific directories were redacted from the
// disclosed versions.

//Version in disclosed package differs from version on RDC system
include 00_directories.do

*********
* BUILD *
*********
cd ${home_dir}/build
//Version in disclosed package differs from version on RDC system
shell qsas 0a_mig5_clean1_bw.sas
do 0b_mig5_clean2_bw.do
do 1_czlist.do
//Version in disclosed package differs from version on RDC system
shell qsas 2_prepresidlocs.sas
//Relies on firmAKM_callable.m - version in disclosed package differs from version on RDC system
do 3_runakm.do
do 4_makesamp.do
do 5_makegrid.do
do 6_multiestab_makelist.do
do 7_firmsize.do

************
* ANALYSIS *
************
cd ${home_dir}/analysis
do commutedist.do
do akmdecomp.do
//Version in disclosed package differs from version on RDC system
shell qR --memsize=100000 --programs=gridmult.R
do gridmulttable.do 
do summstats.do
do psi_commute.do 
do commutedistn.do
do commutedensity.do
do firmsizedecomp.do
do multiestab_commutedist.do
//Version in disclosed package differs from version on RDC system
shell qR --memsize=100000 --programs=gridcorrs.R 
do gridcorrtable.do 


************
* FIGURES  *
************
cd ${home_dir}/analysis/figures
do fig_accessgraphs.do
do fig_psi_commute.do
do fig_commutedensity.do
do fig_commutedistn.do
do fig_multiestab.do

************
* TABLES   *
************
cd ${home_dir}/analysis/tables
do bwdecomp.do
do AKMsummary.do
do commutedensity_origsamp.do
do elasticities.do 






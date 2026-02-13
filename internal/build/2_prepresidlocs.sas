*Program to make a set of CZ-level data files with information about the CZ of residence;
*Note update rawdata_dir and rawdata to be the same as raw_data processed_data to be the same as processed_data in 00_run_all.do

libname rawdata "";
libname resdata "";
libname empdata "";
%let rawdata_dir =;
%let processed_data =;
%let czfiles=&processed_data./CZfiles;


*Get a list of CZs we are going to loop over;
proc import datafile="&processed_data./1_czlist.dta"
     out=czlist;
 run;
data czlist;
 set czlist;
 if paper_cz=1;
 run;
proc sort data=czlist;
 by cz;
 run;
*Put a list of CZs into macros;
 proc sql noprint;
  select distinct cz into :czval1- from czlist;
  %let varCount=&SQLOBS.;
  quit;


*Grab the county-FIPS crosswalk;
proc import datafile="&raw_data./cw_cty_czone.dta" out=czdefs;
 run;
data czdefs;
 set czdefs;
 county_live=put(cty_fips, Z5.0)+0;
 if county_live<57000;
 *exclude Alaska;
 *if cty_fips<02000 | cty_fips>=03000;
 /* 
  *Fix a few county codes;
  output;
  if county_live=12025 then do;
    county_live=12086;
    output;
  end;
  if county_live=8001 then do;
    county_live=8014;
    output;
  end;
 */
 keep county_live czone;
 run;
*Confirm that we have entries for 12086 and 8001;
proc print data=czdefs (where=(czone=28900 | czone=7000));
 run;
proc sort data=czdefs; by county_live; run;

*Prep the residential data, and link to CZ information;
data resdat;
 set resdata.icf_us_residence_cpr (where=(address_year>=2010) in=file1)
     resdata.icf_us_residence_rcf (where=(address_year<2020) in=file2 rename=(county_live=origcty));
 if file1 then origcty=input(substr(geocodefull, 1, 5), 8.);
 county_live=origcty+0;
 if county_live<57000;
 keep pik address_year latitude_live longitude_live county_live;
 run;
proc sort data=resdat;
 by county_live;
 run;
data resdat (rename=(czone=cz_live address_year=year));
 merge resdat (in=resobs)
       czdefs (in=defs);
 by county_live;
 merge=1*(resobs=1)+2*(defs=1);
 *if county_live<57000 | missing(county_live);
 *Exclude Alaska;
 *if county_live<02000 | county_live>=03000 | missing(county_live);
 keep pik address_year latitude_live longitude_live czone county_live merge;
 run;
proc freq data=resdat (where=(merge<3));
 tables county_live*merge / missing;
 title "Counties not matching between residential data and CZ defs";
 run;
proc sort data=resdat (where=(merge=3)) out=resdata (drop=merge); 
 by pik year;
 run;
proc datasets;
 delete resdat;
 run;

*Prep the employer locations data;
proc sort data=empdata.ecf_seinunit_interleave (keep=sein seinunit year quarter leg_latitude leg_longitude)
          out=emploc ;
 by sein seinunit year quarter;
 run;
proc contents data=emploc;
 run;

*Now prepare the LEHD data. Do it in two parts to reduce memory;
proc import datafile="&rawdata_dir./mig5_pikqtime_1022.dta" 
     out=lehd;
  run;
proc sort data=lehd (where=(year<=2015)) out=lehd1;
  by sein seinunit year quarter;
  run;
proc sort data=lehd (where=(year>2015)) out=lehd2;
  by sein seinunit year quarter;
  run;
proc datasets;
 delete lehd;
 run;
data lehdlocs1;
 merge lehd1 (in=fromlehd) emploc;
 by sein seinunit year quarter;
 if fromlehd;
 run;
data lehdlocs2;
 merge lehd2 (in=fromlehd) emploc;
 by sein seinunit year quarter;
 if fromlehd;
 run;
proc datasets;
 delete lehd1 lehd2 emploc;
 run;
proc sort data=lehdlocs1;
 by pik year qtime;
 run;
proc sort data=lehdlocs2;
 by pik year qtime;
 run;
data merged1;
  merge resdata lehdlocs1 (in=fromlehd);
  by pik year;
  if fromlehd;
  samecz=(cz_live=cz) - missing(cz_live);
  if whitenh=1 | blacknh=1;
  if ~missing(e);
  if e<9999998;
  if year<2020;
  rename latitude_live=live_lat;
  rename longitude_live=live_long;
  rename leg_latitude=work_lat;
  rename leg_longitude=work_long;
  rename cz=work_cz;
  rename cz_live=live_cz;
  run;
data merged2;
  merge resdata lehdlocs2 (in=fromlehd);
  by pik year;
  if fromlehd;
  samecz=(cz_live=cz) - missing(cz_live);
  if whitenh=1 | blacknh=1;
  if ~missing(e);
  if e<9999998;
  if year<2020;
  rename latitude_live=live_lat;
  rename longitude_live=live_long;
  rename leg_latitude=work_lat;
  rename leg_longitude=work_long;
  rename cz=work_cz;
  rename cz_live=live_cz;
  run;
proc datasets;
 delete resdata lehdlocs1 lehdlocs2;
 run;

proc freq;
  tables live_cz*samecz / nocol nopercent;
  run;

*Macro programming to prepare a list of CZs;
%macro czloop;
  %do index=1 %to &varCount;
    data reslocs_cz&&czval&index.;
      set merged1 (where=(work_cz=&&czval&index.))
          merged2 (where=(work_cz=&&czval&index.));
      run;
    proc export data=reslocs_cz&&czval&index.
                file="&czfiles./bwobs_cz&&czval&index."
                dbms=stata replace;
      run;
  %end; 
%mend;

%czloop;

%macro czlisting;
  %do index=1 %to &varCount;
    reslocs_cz&&czval&index.
  %end;
%mend;
%macro czoutput;
  %do index=1 %to &varCount;
    if work_cz=&&czval&index. then output reslocs_cz&&czval&index.;
  %end;
%mend;

%macro putstata;
  %do index=1 %to &varCount;
    proc export data=reslocs_cz&&czval&index.
                file="&czfiles./bwobs_cz&&czval&index."
                dbms=stata replace;
      run;
  %end;
%mend;

*data %czlisting;
* set merged;
* %czoutput;
* run;
*%putstata;



/*
raw data cleaning
*/
libname newintlv "";
libname newicf   "";
libname ddata    "";


* main version;
* phf for workers 2010Q1-2022Q1 (101-149);
* r1, ignoring spells with earnings of less than $3800;
data phftemp_akm;
	set newintlv.jhf_interleave(keep=pik sein seinunit1 state e10: e11: e12: e13: e14:);
	if cmiss(of e:)=49 then delete;
	if pik='XXXXXXXXX' then delete;
	if pik='YYYYYYYYY' then delete;	
	if pik='' then delete;
run;
proc export data = phftemp_akm outfile="[ddata]/phftemp_akm.dta" replace;
run;  

* get icf date of birth;
* piklist;
data piks;
set phftemp_akm(keep=pik);
run;
proc sort data=piks(keep=pik);
by pik;
run;
data ddata.m5_piklist;
set piks;
by pik;
if first.pik;
run;

data icf_dob(keep=pik dob);
merge ddata.m5_piklist (in=insample) newicf.icf_us (in=inicf);
by pik;
if insample=1;
run;
proc export data = icf_dob outfile="[ddata]/m5_icf_dob.dta" replace;
run;  


* now get ecf_seinunit sample;
data seinunits;
set phftemp_akm(keep=sein seinunit1 pik);
run;
proc sort data=seinunits;
 by sein seinunit1 pik;
 run;
data seinunit_list(keep=sein seinunit);
 set seinunits(keep=sein seinunit1);
 by sein seinunit1;
 if first.seinunit1;
 seinunit=seinunit1;
run;

data seinunits_temp;
	set newintlv.ecf_seinunit_interleave(keep=sein seinunit year quarter leg_state leg_county  naics2012fnl);
	run;
proc sort data=seinunits_temp;
	by sein seinunit;
run;
data ecf_seinunit(keep=sein seinunit year quarter leg_state leg_county  naics2012fnl);
    merge seinunit_list (in=inseinunitlist) seinunits_temp (in=ecf);
    by sein seinunit;
    if inseinunitlist and year>=2010;
    run;
proc export data = ecf_seinunit outfile="[ddata]/m5_ecf_seinunit.dta" replace;
run;



* EXTRACT EDUCATION FROM ACS 2001-2017;
%let main =    [ddata] ;
%let acspath =     ;
%let acsxwkpath = ;
libname acs (
    "/&acsxwkpath/2001",
    "/&acsxwkpath/2002",
    "/&acsxwkpath/2003",
    "/&acsxwkpath/2004",
    "/&acsxwkpath/2005",
    "/&acsxwkpath/2006",
    "/&acsxwkpath/2007",
    "/&acsxwkpath/2008",
    "/&acsxwkpath/2009",
    "/&acsxwkpath/2010",
    "/&acsxwkpath/2011",
    "/&acsxwkpath/2012",
    "/&acsxwkpath/2013",
    "/&acsxwkpath/2014",
    "/&acsxwkpath/2015",
    "/&acsxwkpath/2016",
    "/&acsxwkpath/2017",
    "/&acspath/2001",
    "/&acspath/2002",
    "/&acspath/2003",
    "/&acspath/2004",
    "/&acspath/2005",
    "/&acspath/2006",
    "/&acspath/2007",
    "/&acspath/2008",
    "/&acspath/2009",
    "/&acspath/2010",
    "/&acspath/2011",
    "/&acspath/2012",
    "/&acspath/2013",
    "/&acspath/2014",
    "/&acspath/2015",
    "/&acspath/2016",
    "/&acspath/2017");
        
%Let syr=92;
%Let samp=100;    
options mprint;
proc sort data = ddata.m5_piklist nodupkey;
    by pik;
run;

%macro vintage(yr);
  %if (&yr.<= 2007) %then %do;
  data acs_&yr.;
  set acs.vpers&yr._1yr (keep = cmid pnum age schl);
  year = &yr.;
  if (schl~=. & schl<=9) then educacs = 1;
  if (schl~=. & schl>=10 & schl<=12) then educacs = 2;
  if (schl~=. & schl>=13 & schl<=13) then educacs = 3;
  if (schl~=. & schl>=14) then educacs = 4;  
  if (age >= 30 & schl~=.) then output;
  run;
  %end;
%else %if (&yr. = 2008 ) %then %do;
  data acs_&yr.;
  set acs.vpers&yr._1yr (keep = cmid pnum age schl);
  year = &yr.;
  if (schl~=. & schl<=17) then educacs = 1;
  if (schl~=. & schl>=18 & schl<=20) then educacs = 2;
  if (schl~=. & schl>=21 & schl<=21) then educacs = 3;
  if (schl~=. & schl>=22) then educacs = 4;  
  if (age >= 30 & schl~=.) then output;
  run;
  %end;  
%else %if (&yr. >= 2009 & &yr.<= 2015) %then %do;
  data acs_&yr.;
  set acs.vpers&yr._1yr (keep = cmid pnum age schl fod1);
  year = &yr.;
  if (schl~=. & schl<=17) then educacs = 1;
  if (schl~=. & schl>=18 & schl<=20) then educacs = 2;
  if (schl~=. & schl>=21 & schl<=21) then educacs = 3;
  if (schl~=. & schl>=22) then educacs = 4;  
  if (age >= 30 & schl~=.) then output;
  run;
  %end;
%else %if &yr. = 2016 %then %do;
  data acs_&yr.;
  set acs.acs2016_vpers_1yr (keep = cmid pnum age schl fod1);
  year = &yr.;
  if (schl~=. & schl<=17) then educacs = 1;
  if (schl~=. & schl>=18 & schl<=20) then educacs = 2;
  if (schl~=. & schl>=21 & schl<=21) then educacs = 3;
  if (schl~=. & schl>=22) then educacs = 4;  
  if (age >= 30 & schl~=.) then output;
  run;
%end;
%else %if &yr. >= 2017 %then %do;
  data acs_&yr.;
  set acs.acs&yr._vpers_1yr (keep = cmid pnum age schl fod1);
  year = &yr.;
  if (schl~=. & schl<=17) then educacs = 1;
  if (schl~=. & schl>=18 & schl<=20) then educacs = 2;
  if (schl~=. & schl>=21 & schl<=21) then educacs = 3;
  if (schl~=. & schl>=22) then educacs = 4;  
  if (age >= 30 & schl~=.) then output;
%end;

proc sort data = acs_&yr.;
by cmid pnum;
run;

data crosswalk_acs&yr.;
set acs.crosswalk_acs&yr.;
run;

proc sort data = crosswalk_acs&yr.;
by cmid pnum;
run;

data acs_&yr. (keep = pik year age schl educacs fod1);
merge acs_&yr. (in=a) crosswalk_acs&yr. (in=b);
by cmid pnum;
if (a & pik~='') then output;
run;

%mend vintage;
%vintage(2001);
%vintage(2002);
%vintage(2003);
%vintage(2004);
%vintage(2005);
%vintage(2006);
%vintage(2007);
%vintage(2008);
%vintage(2009);
%vintage(2010);
%vintage(2011);
%vintage(2012);
%vintage(2013);
%vintage(2014);
%vintage(2015);
%vintage(2016);
%vintage(2017);


data acs_all (keep = pik year age schl educacs);
set 
  acs_2001
  acs_2002
  acs_2003
  acs_2004
  acs_2005
  acs_2006
  acs_2007
  acs_2008
  acs_2009
  acs_2010
  acs_2011
  acs_2012
  acs_2013
  acs_2014
  acs_2015
  acs_2016
  acs_2017;
run;

proc sort data = acs_all;
by pik year;
run;

data acs_all;
set acs_all;
by pik year;
if last.pik then output;
run;

proc sort data = acs_all;
by pik;
run;

*This is the list of piks with education - for our main estimation sample;
data m5_piklist_educacs;
merge ddata.m5_piklist (in=a) acs_all (in=b);
by pik;
if a & b then output;
run;
proc export data = m5_piklist_educacs outfile="&main/m5_piklist_educacs.dta" replace;













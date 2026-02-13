clear all
set more off

set scheme plotplainblind


import excel using "../disclosed/Yi_tabs_T13T26_2.xlsx", sheet("3") cellrange(A3) firstrow clear

*set scheme plotplainblind
*set scheme cleanplots

drop if czgroupC=="Other top 200 CZs"


rename r*_f*_psi psi_1**
reshape long psi_, i(czgroupC commutedist) j(gpvar)
gen multiestab=gpvar-10*floor(gpvar/10)
gen sizecat=floor((gpvar-100*floor(gpvar/100))/10)
gen racegp=(gpvar-1000-10*sizecat-multiestab)/100
rename psi_ psi
encode czgroupC, gen(czgroup)
*keep if inlist(sizecat, 2, 3)
gen cz_size=(3-czgroup)*10+sizecat
label def l_cz_size 11 "Older industrial CZs, size<=10" 12 "Older industrial CZs, size 11-276" ///
                    13 "Older industrial CZs, size>276" ///
                    21 "New sunbelt CZs, size<=10" 22 "New sunbelt CZs, size 11-276" 23 "New sunbelt CZs, size>276"
label values cz_size l_cz_size		    
line psi commutedist if racegp==0 & multiestab==0, lstyle(p1) lpattern(solid) lcolor(sky) || ///
line psi commutedist if racegp==0 & multiestab==1, lstyle(p1) lpattern(shortdash) lcolor(sky) || ///
line psi commutedist if racegp==1 & multiestab==0, lstyle(p2) lpattern(solid) lcolor(reddish) || ///
line psi commutedist if racegp==1 & multiestab==1, lstyle(p2) lpattern(shortdash)  lcolor(reddish) || ///
  ,  by(cz_size, colfirst rows(3) graphr(m(l+10 r+10)) yrescale ///
                 title("") note("") ///
				 legend(position(3)))   ///    
     xscale(log extend) xlabel(0.5 1 2 4 8 16 32) ///
     xtitle("Commute distance (miles, rescaled, log2 scale)") ytitle("Average AKM establishment effect") ///
     legend(label(1 "White (1 estab)") label(2 "White (2+ estab)") ///
            label(3 "Black (1 estab)") label(4 "Black (2+ estab)") ///
            cols(1)) ///
	 saving(../results/figA3.gph, replace)
graph export ../results/figA3.png, replace

/*
                  note("Note: Commute distances are rescaled at the CZ level to set the 75th percentile to 16 miles," ///
                       "local linear models are fit for each CZ, then CZs are averaged by group.") ///
*/



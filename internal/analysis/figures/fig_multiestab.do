use ${output}/multiestab_commutedist_groups, clear

keep if czgroupC<.
drop czgroupA czgroupB
rename r*_f*_psi psi_1**
reshape long psi_, i(czgroupC commutedist) j(gpvar)
gen multiestab=gpvar-10*floor(gpvar/10)
gen sizecat=floor((gpvar-100*floor(gpvar/100))/10)
gen racegp=(gpvar-1000-10*sizecat-multiestab)/100
rename psi_ psi
keep if czgroupC<3

*keep if inlist(sizecat, 2, 3)
gen cz_size=czgroupC*10+sizecat
label def l_cz_size 11 "Older industrial, <=10" 12 "Older industrial, 11-median" ///
                    13 "Older industrial, >median" ///
                    21 "New sunbelt, <=10" 22 "New sunbelt, 11-median" 23 "New sunbelt, >median"
label values cz_size l_cz_size		    
line psi commutedist if racegp==0 & multiestab==0, lstyle(p1) lpattern(solid) || ///
line psi commutedist if racegp==0 & multiestab==1, lstyle(p1) lpattern(dash) || ///
line psi commutedist if racegp==1 & multiestab==0, lstyle(p2) lpattern(solid)  || ///
line psi commutedist if racegp==1 & multiestab==1, lstyle(p2) lpattern(dash)  || ///
  ,  by(cz_size, colfirst rows(3) graphr(m(l+10 r+10)) yrescale ///
                 title("Average firm quality by commute distance & firm size") ///
                  note("Note: Commute distances are rescaled at the CZ level to set the 75th percentile to 16 miles," ///
                       "local linear models are fit for each CZ, then CZs are averaged by group."))   ///    
     xscale(log) xlabel(1 5 10 25 50) ///
     xtitle("Commute distance (miles, rescaled)") ytitle("Average firm premium") ///
     legend(label(1 "White (1 estab)") label(2 "White (2+ estab)") ///
            label(3 "Black (1 estab)") label(4 "Black (2+ estab)")) ///
     saving(${output}/fig_multiestab, replace)
graph export ${output}/fig_multiestab.png, replace


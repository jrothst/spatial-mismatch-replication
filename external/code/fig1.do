
import excel using "../disclosed/Yi_tabs_T13T26_1.xlsx", sheet("2") cellrange(A4) firstrow clear

set scheme plotplainblind

drop if czgroupC=="Other top 200 CZs"
	
line wh_fr_n wh_fr_psi3 bl_fr_n bl_fr_psi3 origdist if czgroupC=="Older industrial CZs", ///
     lstyle(p1 p1 p2 p2) lpattern(solid dash solid dash) lcolor( sky sky reddish reddish) ///
	 title("") subtitle("Older industrial CZs") ///
	 xscale(log extend) yscale(log extend) xlabel(0.5 1 2 5 10 30) ylabel(0.001 0.01 0.1 0.5) ///
	 xtitle("Distance from home (miles, rescaled)") ///
	 ytitle("Fraction of jobs in CZ") ///
	 legend(label(1 "White: all jobs") label(2 "White: good jobs") ///
 	        label(3 "Black: all jobs") label(4 "Black: good jobs") ring(0) pos(4) cols(1)) ///
	 name(ul, replace) saving(../results/fig1-panelA.gph, replace)
graph export ../results/fig1-panelA.png, replace
line wh_fr_n wh_fr_psi3 bl_fr_n bl_fr_psi3 origdist if czgroupC=="New sunbelt CZs", ///
     lstyle(p1 p1 p2 p2) lpattern(solid dash solid dash) lcolor( sky sky reddish reddish) ///
	 title("") subtitle("Newer sunbelt CZs") ///
	 xscale(log extend) yscale(log extend) xlabel(0.5 1 2 5 10 30) ylabel(0.001 0.01 0.1 0.5) ///
	 xtitle("Distance from home (miles, rescaled)") ///
	 ytitle("Fraction of jobs in CZ") ///
	 legend(off) ///
	 name(ur, replace) saving(../results/fig1-panelC.gph, replace)
graph export ../results/fig1-panelC.png, replace

foreach x in wh_fr_n wh_fr_psi3	bl_fr_n bl_fr_psi3 {
	gen rel_`x'=`x'/wh_fr_n
}
line rel_wh_fr_n rel_wh_fr_psi3 rel_bl_fr_n rel_bl_fr_psi3 origdist if czgroupC=="Older industrial CZs", ///
     lstyle(p1 p1 p2 p2) lpattern(solid dash solid dash) lcolor( sky sky reddish reddish) ///
	 title("") subtitle("Older industrial CZs:" "Relative to share of all jobs" "within distance radius for whites", span) ///
	 xscale(log extend) yscale(extend range(0.9 1.4)) xlabel(0.5 1 2 5 10 30) ylabel(0.9 (0.1) 1.4) ///
	 xtitle("Distance from home (miles, rescaled)") ///
	 ytitle("Relative frac. of jobs in CZ ") ///
	 legend(off) ///
	 name(ll, replace) saving(../results/fig1-panelB.gph, replace)
graph export ../results/fig1-panelB.png, replace
line rel_wh_fr_n rel_wh_fr_psi3 rel_bl_fr_n rel_bl_fr_psi3 origdist if czgroupC=="New sunbelt CZs", ///
     lstyle(p1 p1 p2 p2) lpattern(solid dash solid dash) lcolor( sky sky reddish reddish) ///
	 title("") subtitle("Newer sunbelt CZs:" "Relative to share of all jobs" "within distance radius for whites", span) ///
	 xscale(log extend) yscale(extend range(0.9 1.4)) xlabel(0.5 1 2 5 10 30) ylabel(0.9 (0.1) 1.4) ///
	 xtitle("Distance from home (miles, rescaled)") ///
	 ytitle("Relative frac. of jobs in CZ") ///
	 legend(off) ///
	 name(lr, replace) saving(../results/fig1-panelD.gph, replace)
graph export ../results/fig1-panelD.png, replace
graph combine ul ur ll lr, ///
     saving(../results/fig1-combined.gph, replace)
graph export ../results/fig1-combined.png, replace

	 
	 

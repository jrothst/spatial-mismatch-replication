
import excel using "../disclosed/Yi_tabs_T13T26_1.xlsx", sheet("4") cellrange(A3) firstrow clear

set scheme plotplainblind

drop if czgroupC=="Other top 200 CZs"

line p25 p50 p75 decile if blacknh=="white", lstyle(p1 p1 p1) lpattern(shortdash solid dash) lcolor(sky sky sky) || ///
line p25 p50 p75 decile if blacknh=="black", lstyle(p2 p2 p2) lpattern(shortdash solid dash) lcolor(reddish reddish reddish) ///
  by(czgroupC, title("") note("")) ///
  legend(order(3 "White: 75th %ile" 6 "Black: 75th %ile" ///
               2 "White: 50th %ile" 5 "Black: 50th %ile" ///
			   1 "White: 25th %ile" 4 "Black: 25th %ile") cols(2)) ///
  xtitle("Alpha (decile within CZ)") ytitle("Commute distance (miles)") xlabel(1 (1) 10)  ///
  saving(../results/figA4.gph, replace)
graph export ../results/figA4.png, replace

/*  title("Distribution of commute distances by race and worker skill") */

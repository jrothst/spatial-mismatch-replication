use ${output}/commutedistn_groups, clear

keep if czgroupC<.
line p25 p50 p75 gp_z_alpha if racegp==1, lstyle(p1 p1 p1) lpattern(longdash solid shortdash) || ///
  line p25 p50 p75 gp_z_alpha if racegp==0, lstyle(p2 p2 p2) lpattern(longdash solid shortdash) ///
  by(czgroupC) ///
    xtitle("Alpha (decile within CZ)") ytitle("Commute distance") xlabel(1(1)10) ///
    legend(order(3 "Black: 75th %ile" 6 "White: 75th %ile" ///
                 2 "Black: 50th %ile" 5 "White: 50th %ile" ///
                 1 "Black: 25th %ile" 4 "White: 25th %ile" )) ///
    saving(${output}/fig_commutedistn, replace)
    
    
graph export ${output}/fig_commutedistn.png, replace

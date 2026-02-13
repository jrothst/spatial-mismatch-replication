clear all
set more off


import excel using "../disclosed/Yi_tabs_T13T26_2.xlsx", sheet("2") cellrange(A3) firstrow clear
drop if czgroupC=="Other top 200 CZs"

gen czgp=1 if czgroupC=="Older industrial CZs"
replace czgp=2 if czgroupC=="New sunbelt CZs"
label define czgpnum 1 "Older industrial CZs" 2 "Newer sunbelt CZs"
label values czgp czgpnum
/*
line dens_r0 dens_r1 distpt if distpt>0, ///
  lstyle(p1 p2 ) lpattern(solid dash ) ///
  xscale(log extend) xlabel(0.5 1 5 10 25 50) ///
  by(czgroupC, title("Density of log commute distances by race and region")) ///
  xtitle("Commute distance (miles, rescaled, log scale)") ///
  legend(label(1 "White") label(2 "Black")) ///
  saving(fig_commutedensity.gph, replace)
graph export fig_commutedensity.png, replace
*/

*Work out CDFs
* Method: We have a set of points (x,y) on the density curves. Assume densities
*         are piecewise linear connecting these points. Extrapolate the curves
*         one extra point above and below, forcing the density to equal 0 at these
*         points and the slope to be the same as in the next linear piece. Then
*         use the original and extrapolated points to compute the CDF, again
*         assuming piecewise linear densities.
 *Step 1 - add extra point above our initial range
  sort czgroupC distpt
  by czgroupC: gen i=_n-1
  by czgroupC: gen duplic=1+(_N==_n)
  expand duplic, gen(endpoint)
  replace i=i+1 if endpoint==1
  replace endpoint=1 if distpt==0
  forvalues r=0/1 {
    gen newdens`r'=dens_r`r'
	replace newdens`r'=. if endpoint==1
  }

 *Step 2 - extrapolate endpoints
  sort czgroupC i
  isid czgroupC i
  forvalues r=0/1 {
  	rename newdens`r' d`r'
    by czgroupC: gen x`r'=ln(distpt) if endpoint==0
    by czgroupC: replace x`r'=x`r'[2] - d`r'[2]*((x`r'[3]-x`r'[2])/(d`r'[3]-d`r'[2])) if _n==1
    by czgroupC: replace x`r'=x`r'[_N-1] - d`r'[_N-1]*((x`r'[_n-1]-x`r'[_N-2])/(d`r'[_N-1]-d`r'[_N-2])) if _n==_N
	by czgroupC: replace d`r'=0 if inlist(_n, 1, _N)
  }
  
 *Step 3 - calculate CDFs
  sort czgroupC i
  forvalues r=0/1 {
    by czgroupC: gen cdfcontrib`r'=0 if i==0
    by czgroupC: replace cdfcontrib`r'=0.5*(d`r'+d`r'[_n-1])*(x`r'-x`r'[_n-1]) if i>0	
	by czgroupC: gen cdf`r'=sum(cdfcontrib`r')
	gen distance`r'=exp(x`r')
  }


  line cdf0 distance0 if distance0>=0.29, lstyle(p1) lpattern(solid) lcolor(sky) || ///
  line cdf1 distance1 if distance1>=0.29, lstyle(p2) lpattern(dash) lcolor(reddish) ///
	xscale(log extend) xlabel(0.5 1 5 10 25 50) ylabel(0 (0.25) 1) ///
    by(czgp, title("CDF of commute distance by race and region")) ///
    xtitle("Commute distance (miles, rescaled, log scale)") ///
    legend(label(1 "White") label(2 "Black")) ///
    saving(../results/figA2.gph, replace)
graph export ../results/figA2.png, replace


// Make table of quantiles of commute distance
// Here, we need to interpolate - we have certain points on the inverse CDF,
// but not all of them. To interpolate, note that we assumed the PDF was piecewise
// linear, so the CDF is piecewise quadratic (in log distance). So we need to work
// out the coefficients of that quadratic, then invert.
// 1. find the segment where our point (x, p) is located
// 2. Let m be the slope of the PDF in this segment, and (x0, d0) the beginning
//    of the segment (so the intercept is d0-m*x0). Let p0 =F(x0).
// 3. The quadratic is p0 + integral from x0 to x of (d0-m*x0)+m*z dz
//    = p0 + (d0-m*x0)*(x-x0) + 0.5*m*(x^2-x0^2).
// 4. Setting this equal to p gives us a quadratic equation:
//     a = p0 - (d0-m*x0)*x0 - 0.5*m*(x0^2)
//     b = d0 - m*x0
//     c = 0.5*m
sort czgroupC i
local quantlist 10 25 50 75 90
tempfile base
save `base'
forvalues r=0/1 {
  use `base', clear
  gen ptile=.
  foreach q of local quantlist {
  	replace ptile=`q'/100 if cdf`r'>=`q'/100 & cdf`r'[_n-1]<`q'/100
  }
  by czgroupC: gen m=(d`r'-d`r'[_n-1])/(x`r'-x`r'[_n-1])
  by czgroupC: gen intercept=d`r'[_n-1] - m*x`r'[_n-1]
  gen a=0.5*m
  by czgroupC: gen b=intercept
  by czgroupC: gen c=cdf`r'[_n-1] - intercept*x`r'[_n-1] - 0.5*m*(x`r'[_n-1]^2) - ptile
  gen root1=(-b + sqrt(b^2 - 4*a*c))/(2*a)
  gen root2=(-b - sqrt(b^2 - 4*a*c))/(2*a)
  gen lquant=root1 if root1<=x`r' & root1>x`r'[_n-1]
  replace lquant=root2 if root2<=x`r' & root2>x`r'[_n-1]
  
  gen lquant_ub=x`r'
  by czgroupC: gen lquant_lb=x`r'[_n-1]
  keep czgroupC czgp ptile lquant*
  rename lquant* lquant`r'*
  keep if ptile<.
  tempfile race`r'
  save `race`r''
}
use `race0', clear
merge 1:1 czgroupC czgp ptile using `race1'

gen quant0=exp(lquant0)
gen quant1=exp(lquant1)

// Code to overlay quantiles on graph to check
/*
  append using `base'
  line cdf0 distance0 if distance0>=0.29, lstyle(p1) lpattern(solid) || ///
  line cdf1 distance1 if distance1>=0.29, lstyle(p2) lpattern(dash) || ///
  scatter ptile quant0 || scatter ptile quant1 , ///
	xscale(log extend) xlabel(0.5 1 5 10 25 50) ylabel(0 (0.25) 1) ///
    by(czgp, title("CDF of commute distance by race and region")) ///
    xtitle("Commute distance (miles, rescaled, log scale)") ///
    legend(label(1 "White") label(2 "Black")) ///
*/
sort czgp ptile
keep czgroupC ptile quant0 quant1
keep if ptile<.
replace quant0=round(quant0, 0.1)
replace quant1=round(quant1, 0.1)
replace ptile=round(ptile*100)
export excel using "../results/tableA4_lehd.xlsx", replace firstrow(variables) cell(d4)
putexcel set "../results/tableA4_lehd.xlsx", modify
putexcel D2 = "Table A-3. Quantiles of commute distance (in miles) by CZ group and race"
putexcel D4 = "CZ group"
putexcel E4 = "Percentile"
putexcel F4 = "White"
putexcel G4 = "Black"
putexcel F5:G14 , overwritefmt nformat(0.0)
putexcel save








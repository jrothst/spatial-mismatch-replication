sink("gridmult.log")

# This needs to be edited to the "analysis" subdirectory of the directory set in the Stata global "home_dir" from 00_directories.
home_dir <- "<home directory>/analysis/"
# This needs to be edited to the same directory as in the Stata global "processed_data" from 00_directories.
processed_data<-"<scratch directory>/"

setwd(home_dir)
library(haven)
library(data.table)
library(tidyverse)
library(gdata)

#Function to make distances 
makedistances<-function(griddata, unit=0.5) {
  #Unit is number of miles between grid points
  npts<-max(griddata$gridpt)
  xdiff<-unit*outer(griddata$grid_x, griddata$grid_x, '-')
  ydiff<-unit*outer(griddata$grid_y, griddata$grid_y, '-')
  return(sqrt(xdiff^2+ydiff^2))
}

#Function to compute the weighted sum of y, where weights may depend on
# the location of y relative to some base location, then sum over base 
# locations with weights x.
#E.g.: To compute the number of A jobs within 3 miles of the average black worker,
#      y = count of A jobs at location,
#      x = share of black workers at location
#      W = indicator for distance<3 miles between location i and j (W<-distancemat<=radius+tol)
#Note that both x and y can be data frames with multiple variables
sum_dist<-function(xvars, yvars, W){
  unmatrix(t(as.matrix(xvars)) %*% as.matrix(W) %*% as.matrix(yvars))
}

#Function to apply sum_dist using as weight a disc of radius r
sum_dist_disc<-function(radius, xvars, yvars, distmat, tol=.Machine$double.eps){
  W<-distmat<=radius+tol
  sum_dist(xvars, yvars, W)
}

#Apply sum_dist_disc across a range of radii, and make a dataset
radialcdf<-function(distances, x, y, D){
  result<-tibble(radius=distances,
                 as.data.frame(t(sapply(distances, sum_dist_disc, xvars=x, yvars=y, distmat=D))))
  result<-result %>%
    rename_with(~ gsub(":", "_", .x, fixed=TRUE))
}


runonecz<-function(cz, distlist=c(1:5), rescale=FALSE){
  print(paste("Starting CZ ", cz))
  #Read in grid
  griddat<-read_dta(file.path(processed_data,  
                              paste("grid_cz", cz, ".dta", sep="")))
  #Make distance
  distancemat<-makedistances(griddat)
  #Clean
  griddat[is.na(griddat)]<-0
  #Normalize x variables
  griddat %>% 
    mutate(wh=live_whitenh/sum(live_whitenh),
           bl=live_blacknh/sum(live_blacknh),
           n=(live_whitenh+live_blacknh)/sum(live_whitenh+live_blacknh),
           whe1=live_wh_n_e1/sum(live_wh_n_e1),
           whe2=live_wh_n_e2/sum(live_wh_n_e2),
           ble1=live_bl_n_e1/sum(live_bl_n_e1),
           ble2=live_bl_n_e2/sum(live_bl_n_e2)) %>%
    arrange(gridpt) %>%
    select(wh, bl, n, whe1, whe2, ble1, ble2) ->
    x
  #Make y variables
  griddat %>%
    mutate(njobs=work_blacknh+work_whitenh) %>%
    arrange(gridpt) %>%
    mutate(
      fr_n=njobs/sum(njobs),
      fr_bln=work_blacknh/sum(work_blacknh),
      fr_whn=work_whitenh/sum(work_whitenh),
      fr_psi3=work_n_psi3/sum(work_n_psi3),
      fr_bl_psi3=work_bl_n_psi3/sum(work_bl_n_psi3),
      fr_wh_psi3=work_wh_n_psi3/sum(work_wh_n_psi3),
      fr_e1_psi3=work_n_e1_psi3/sum(work_n_e1_psi3),
      fr_e2_psi3=work_n_e2_psi3/sum(work_n_e2_psi3),
      n_e1=work_n_e1_psi1+work_n_e1_psi2+work_n_e1_psi3,
      n_e2=work_n_e2_psi1+work_n_e2_psi2+work_n_e2_psi3,
      fr_e1=n_e1/sum(n_e1),
      fr_e2=n_e2/sum(n_e2)) %>%
    select(fr_n, fr_bln, fr_whn, fr_psi3, fr_bl_psi3, fr_wh_psi3, fr_e1, fr_e2, fr_e1_psi3, fr_e2_psi3) ->
    y
  #If rescale=TRUE, adjust distlist to reflect commuting time in CZ
  if (rescale==TRUE) {
    factor<-commutedists$p75[commutedists$cz==cz]
    distlist_rescale<-distlist*factor/16
  }
  results<-radialcdf(distlist_rescale, x=x, y=y, D=distancemat)
  results$cz<-cz
  results$origdist<-distlist
  print(paste("Finishing CZ ", cz))
  return(results)
} 

#Make a list of CZs in Paper
czlist<-read_dta(file.path(processed_data, "1_czlist.dta")) %>%
          filter(paper_cz==1) %>%
          select(cz)
czlist<-czlist$cz
czlist

#Load normalization factors
commutedists<-read_dta(file.path(processed_data, "commutedist.dta")) %>% select(cz, p75)

distlist<-c(0.5, 1, 1.5, c(2:20), 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100)

results<-bind_rows(lapply(czlist, runonecz, distlist, rescale=TRUE))
write_dta(results, file.path(processed_data, "gridmult.dta"))        
sink()


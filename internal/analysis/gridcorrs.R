
# This needs to be edited to the "analysis" subdirectory of the directory set in the Stata global "home_dir" from 00_directories.
home_dir <- "<home directory>/analysis/"
# This needs to be edited to the same directory as in the Stata global "processed_data" from 00_directories.
processed_data<-"<scratch directory>/"

library(haven)
library(data.table)
library(tidyverse)
library(gdata)
#library(tidylog)
library(logr)

setwd(home_dir)
logfile<-file.path(home_dir, "gridcorrs.log")
lf<-log_open(logfile, logdir=FALSE, autolog=FALSE)
log_code()

#Function to make distances 
makedistances<-function(griddata, unit=0.5) {
  #Unit is number of miles between grid points
  npts<-max(griddata$gridpt)
  xdiff<-unit*outer(griddata$grid_x, griddata$grid_x, '-')
  ydiff<-unit*outer(griddata$grid_y, griddata$grid_y, '-')
  return(sqrt(xdiff^2+ydiff^2))
}

pwcorr<-function(data, vars, weight){
  pairs<-combn(vars, 2, simplify=FALSE)
  k<-length(pairs)
  df<-data.frame(var1=rep(0,k), var2=rep(0, k), rho=rep(NA, k), n=rep(0,k))
  for(i in 1:k){
    v1<-pairs[[i]][1]
    v2<-pairs[[i]][2]
    pairdata<-data %>% select(all_of(v1), all_of(v2)) %>%
      mutate(wt=weight) %>%
      rename("v1"=v1, "v2"=v2) %>% 
      filter(!is.na(v1) & !is.na(v2) & !is.na(wt) & wt>0)
    df[i,1]<-v1
    df[i,2]<-v2
    rho<-cov.wt(pairdata[,c("v1","v2")], wt=pairdata$wt, cor=TRUE)
    df[i,3]<-rho$cor["v1", "v2"]
    df[i,4]<-rho$n.obs	
  }
  return(as_tibble(df))
}

#No longer used
makecorrs<-function(data){
  resvars<-c("fbl", "alpha", "alpha_bl", "alpha_wh")
  workvars<-c("psi", "psi_bl", "psi_wh")
  allcorr <- pwcorr(data, vars=c(resvars, workvars), weight=data$reswgt)
  #rescorr   <-pwcorr(data, vars=resvars,              weight=data$reswgt)
  #workcorr  <-pwcorr(data, vars=workvars,   weight=data$workwgt)
  #bothcorr  <-pwcorr(data, vars=c(resvars, workvars), weight=data$bothwgt) %>%
  #  filter(var1 %in% resvars & var2 %in% workvars)
  #allcorr<-bind_rows(rescorr, workcorr, bothcorr)
return(allcorr)
}

#Function to compute the smoothed version of our work variables,
# using all grid points in a given radius to average
smoother<-function(data, distmat, radius, weight, tol=.Machine$double.eps){
  k<-length(weight)
  wt<-weight
  wt[is.na(wt)]<-0
  W<-(distmat<=radius+tol) 
  W[,wt<=0]<-0
  wtmat<-matrix(rep(wt, ncol(data)), nrow=k)
  wtmat[is.na(data)]<-0
  totwgt<- W %*% wtmat
  dat<-data
  dat[wtmat<=0]<-0
  wy<-dat * rep(wt, ncol(dat))
  Wwy<- W %*% as.matrix(wy)
  
  smoothy<- Wwy / totwgt
  smoothy[is.na(data)]<-NA
  colnames(smoothy) <-colnames(data)
  smoothy<-as_tibble(smoothy)
  return(smoothy)
}

runonecz<-function(cz, distlist=c(0, 1, 2), rescale=FALSE){
  log_print(paste("Starting CZ ", cz))
  #Read in grid
  griddat<-read_dta(paste(processed_data, "grid_cz",
                          cz, ".dta", sep=""))
    log_print(paste("Number of gridpoints is ", dim(griddat)[1], ": ",
                max(griddat$grid_x), " by ", max(griddat$grid_y)))
  #Make distance
  distancemat<-makedistances(griddat)
  #Clean
  #Prepare variables
   griddat %>%
     rename(psi=work_psi,
            psi_bl=work_bl_psi,
            psi_wh=work_wh_psi,
            alpha=live_alpha,
            alpha_bl=live_bl_alpha,
            alpha_wh=live_wh_alpha
            ) %>%
     mutate(fbl=live_blacknh/(live_whitenh+live_blacknh),
            work_fbl=work_blacknh/(work_whitenh+work_blacknh),
            reswgt=live_whitenh+live_blacknh,
            workwgt=work_whitenh+work_blacknh,
            bothwgt=sqrt(reswgt*workwgt),
            alpha_bl=ifelse(fbl>0, alpha_bl, NA),
            alpha_wh=ifelse(fbl<1, alpha_wh, NA),
            psi_bl=ifelse(work_fbl>0, psi_bl, NA),
            psi_wh=ifelse(work_fbl<1, psi_wh, NA)
            ) %>%
     select(grid_x, grid_y, gridpt, 
            reswgt, workwgt, bothwgt,
            alpha, psi, fbl, alpha_wh, alpha_bl, psi_wh, psi_bl) -> griddat

  corrvars<-c("fbl", "alpha", "alpha_bl", "alpha_wh", "psi", "psi_bl", "psi_wh")

  corrs0<-pwcorr(griddat, vars=corrvars, weight=griddat$reswgt) %>% 
    mutate(radius=ifelse(var1 %in% c("psi", "psi_bl", "psi_wh") | 
                         var2 %in% c("psi", "psi_bl", "psi_wh"), 0, NA))
  log_print(corrs0 %>% mutate(cz=cz))
  k<-length(distlist)
  onecorr<-function(radius){
    smooth<-smoother(griddat[,c("psi", "psi_bl", "psi_wh")],
                     distancemat, radius, griddat$workwgt)
    smoothed<-griddat %>% select(!c(psi, psi_bl, psi_wh)) %>% bind_cols(smooth)
    corrs<-pwcorr(smoothed, vars=corrvars, weight=smoothed$reswgt) %>%
      mutate(radius=radius)
    return(corrs)
  }
  #corrs1<-onecorr(5)
  allradii<-bind_rows(lapply(distlist, onecorr))
  allradii<-allradii %>% filter(var1 %in% c("psi", "psi_bl", "psi_wh") | 
                                  var2 %in% c("psi", "psi_bl", "psi_wh"))
  allradii<-bind_rows(corrs0, allradii) %>% mutate(cz=cz)
  return(allradii)
  print(paste("Finishing CZ ", cz))
}


#Make a list of the 17 paper CZs (outside alaska)
czlist<-read_dta(file.path(paste0(processed_data, "1_czlist.dta")) %>%
          filter(paper_cz==1) %>%   
          arrange(desc(totbw)) %>%              #Sort by descending size
          select(cz)
czlist<-czlist$cz

#distlist<-c(1:5)
#distlist<-c(0.5, 1, 2, 30, 40, 50, 90, 100)
distlist<-0.5*c(1:10)

log_print("CZ list:")
log_print(czlist)
log_print("Distance list:")
log_print(distlist)
results<-bind_rows(lapply(czlist, runonecz, distlist))

write_dta(results, file.path(processed_data, "gridcorrs.dta"))        
log_print("Finished writing data")

log_close()

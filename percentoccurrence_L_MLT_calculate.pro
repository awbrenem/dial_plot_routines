;Determine the %occurrence of some quantity in bins of L and MLT
;The output values have size  (nshells,nthetas)

; %occ = [number * (1/8)]/dt

; where dt = block size (sec) --> like 10 sec or 1 min. Not (in general) the sampling rate
; and number = number of counts above certain threshold in time t0 to t0+dt

;-------------------------------------------------------------------------------
;Ex. Calculate the %occ for coherence values of hiss due to ULF modulation.
;--let's focus on coherence at ~1min timescales.
;--let dt = 30 min. Not sure what the resolution on the coherence calculation is,
;--but let's say (due to sliding spec) it's 30 sec. There are then 30*2 = 60
;--coherence calculations in a time dt. If we see 60 coherence values above
;--a certain threshold during this time, then %occ=100

;-------------------------------------------------------------------------------
; Ex. Calculate the %occ for RBSP Filterbank data (8 Samples/sec).
;--Let dt=60 sec. There are 60*8=480 FBK blocks in this time. If we see 480 large
;--amplitude peaks during this time then %time=100.
;--NOTE: Since the FBK data is spin modulated its probably best to have dt as a multiple of
;--half a spin period.
;-------------------------------------------------------------------------------

;Once we've calculated %occ for a single dt, we need to determine it for
;a single sector of L,MLT. For example, if a single sector has 5 dt chunks and
;each sees a wave above the threshold 50% of the time, then the duty cycle
;for that wave in that sector is (50 + 50 + 50 + 50 + 50)/5. = 50%



;l_vals can be Lshell or deltaL from plasmapause, etc.

;KEYWORDS
;nanLshell (NOT YET IMPLEMENTED) --> if Lshell is undefined (e.g. no Tsy model solutions) then set NaN values to this number. 
;              Typically set to a large number (like 50), so that the open field line values can be plotted
;              on the dial plots. 


;; Written by Aaron W Breneman 2013-03-12
;; Modified and generalized on 2018-02-06


;; CURRENT TESTING
;; ---I've set the threshold amplitude to 0 mV/m and the return results indicate that each
;; 	freq in each sector has a 100% duty cycle which is good!
;; ---I've tested this by isolating a chunk of data during a single apogee pass where
;; 	Mlat ranged from 6-7 and Lshell ranged from 6-7 (i.e. a single grid bin). During this
;; 	time the tplot variable npk_percent showed that peak values above 1 mV/m with dt=60 seconds
;; 	occurred with a 31.6% duty cycle. When I then plotted the binned data using
;; 	rbsp_survey_fbk_plot.pro the %-time value in the single bin was exactly 31.6%


;Input tplot variables need to have a cadence of dt.


function percentoccurrence_L_MLT_calculate,$
  dt,$
  npk_in_dt,$
  pk_in_dt,$
  mlt_vals,$
  l_vals,$
  deltaL_pp=deltaL_pp,$
  grid=grid,$
  nanLshell=nanLshell



  if ~keyword_set(grid) then begin
    dlshell = 0.5                   ;delta-Lshell for grid	
    lmin = 2
    lmax = 7
    dtheta = 1.                     ;delta-theta (hours) for grid
    tmin = 0.
    tmax = 24.
    grid = return_L_MLT_grid(dtheta,dlshell,lmin,lmax,tmin,tmax)
  endif



get_data,npk_in_dt,data=npk
get_data,pk_in_dt,data=pk
get_data,mlt_vals,data=mlt
get_data,l_vals,data=lshell

;Calculate dt
sr = sample_rate(npk.x,/average)
sample_period = 1/sr

     ;Extract all non NaN values
     goo = where(finite(npk.y) eq 1)
     if goo[0] ne -1 then begin
        npk = {x:npk.x[goo],y:npk.y[goo]}
        pk = {x:pk.x[goo],y:pk.y[goo]}
        mlt = {x:mlt.x[goo],y:mlt.y[goo]}
        lshell = {x:lshell.x[goo],y:lshell.y[goo]}
     endif

     mlt = mlt.y
     lshell = lshell.y


;;--------------------------------------------------
;; Calculate the percent time for each "dt"
;; %T = 1/(8*dt)*npk
;;--------------------------------------------------

;dt = 600. ;for 10 min
;sample_period = 30. ;sec


     per_npk = npk.y * sample_period/dt
     ;per_nav = nav.y * sample_period/dt
     store_data,'npk_percent',data={x:npk.x,y:per_npk}
     ;store_data,rbspx+'_nav'+optstr+'_percent',data={x:nav.x,y:per_nav}





;; ******************************************************
;; TESTING: Use this to isolate a part of the orbit to see if data are binning correctly
;; ******************************************************
  ;if keyword_set(testing) then begin
;
;     get_data,'npk_percent',data=npk
;     t0 = time_double('2012-10-15/20:00')
;     t1 = time_double('2012-10-15/20:18')
;
;     goo = where((npk.x lt t0) or (npk.x gt t1))
;
;     npk.y[goo] = 0
;     store_data,rbspx+'_npk'+optstr+'_percent',data=npk
;
;
;     get_data,rbspx+'_lshell',data=npk
;     npk.y[goo] = 0
;     store_data,rbspx+'_lshell',data=npk
;     get_data,rbspx+'_mlt',data=npk
;     npk.y[goo] = 0
;     store_data,rbspx+'_mlt',data=npk
;
;     per_npk[goo] = 0.
;     get_data,rbspx+'_mlt',data=mlt
;     get_data,rbspx+'_lshell',data=lshell
;
;  endif
;; ******************************************************




  nshells = grid.nshells
  nthetas = grid.nthetas
  grid_lshell = grid.grid_lshell
  grid_mlt = grid.grid_theta


;; Final saved FBK peak values
  per_peaks = fltarr(nshells,nthetas)
  ;per_averages = fltarr(nshells,nthetas)
  peaks = fltarr(nshells,nthetas)
  ;averages = fltarr(nshells,nthetas)
  counts = fltarr(nshells,nthetas)



;;--------------------------------------------------
;;This histogram loop works. I've tested it against an explicit
;;nested loop that loops over all values of L and MLT. The histogram
;;version is much faster
;;--------------------------------------------------

  for i=0,n_elements(grid_lshell)-2 do begin

     ;;select only current Lshell slice
     l1 = grid_lshell[i]
     l2 = grid_lshell[i+1]

     ;;make sure that only allowed MLT values are used
     m1 = grid_mlt[0]
     m2 = grid_mlt[n_elements(grid_mlt)-1]


     print,l1,l2
     print,'***'
     print,m1,m2


     ;;--works
     goo = where(((lshell ge l1) and (lshell lt l2)) and ((mlt ge m1) and (mlt lt m2)))

     if goo[0] ne -1 then begin
        mlt_tmp = mlt[goo]
        per_npk_tmp = per_npk[goo]
        ;per_nav_tmp = per_nav[goo]
        pk_tmp = pk.y[goo]
        ;av_tmp = av.y[goo]

        nsamples = HISTOGRAM(mlt_tmp,reverse_indices=ri,nbins=nthetas,binsize=grid.dtheta,min=grid.grid_theta[0],locations=loc)
        ;; nsamples -> the number of "dt" chunks in each MLT bin for the current Lshell range


;; nsamples[*] = 10.

        ;; Starting location of each MLT bin
        ;; RBSP_EFW> print,loc
        ;;      0.00000      1.00000      2.00000      3.00000      4.00000      5.00000      6.00000
        ;;      7.00000      8.00000      9.00000      10.0000      11.0000      12.0000      13.0000
        ;;      14.0000      15.0000      16.0000      17.0000      18.0000      19.0000      20.0000
        ;;      21.0000      22.0000      23.0000

        ;; These are the actual values of the dt elements of theta bin "b" and freq "f"
        ;; 		print,'Local times for current bin are: '
        ;; 		if ri[b] ne ri[b+1] then print,(mlt_tmp[ri[ri[b] : ri[b+1]-1]])
        ;; 		print,'Peak values corresponding to the current bin are: '
        ;; 		if ri[b] ne ri[b+1] then print,(per_npk_tmp[ri[ri[b] : ri[b+1]-1],f])


        ;; For each theta bin in current Lshell range let's tally up all the actual values of each "dt" chunk
        ;; and divide by their total. This is step #2 above and represents the overall %time in each
        ;; sector that waves above a certain amplitude threshold exist.
        for b=0,nthetas-1 do if ri[b] ne ri[b+1] then per_peaks[i,b] = total(per_npk_tmp[ri[ri[b] : ri[b+1]-1]],/nan)/nsamples[b]
        ;for b=0,nthetas-1 do if ri[b] ne ri[b+1] then per_averages[i,b] = total(per_nav_tmp[ri[ri[b] : ri[b+1]-1]],/nan)/nsamples[b]

        ;Peak value in each sector
        for b=0,nthetas-1 do if ri[b] ne ri[b+1] then peaks[i,b] = max(pk_tmp[ri[ri[b] : ri[b+1]-1]],/nan)
        ;for b=0,nthetas-1 do if ri[b] ne ri[b+1] then averages[i,b] = max(av_tmp[ri[ri[b] : ri[b+1]-1]],/nan)

        counts[i,*] = nsamples

     endif
  endfor


;; Save values in structure and add to "info"
  vals = {percent_peaks:per_peaks,$
          peaks:peaks,$
          counts:counts}

  return,vals


end

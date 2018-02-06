;Take an input timeseries of data and determine the number of
;times that the values are above a certain threshold in a
;time chunk of size "dt"

;Outputs two tplot variables.
;--pk - maximum value that occurred each dt.
;--npk - number of occurrences above the threshold that occurred each dt.

;e.g. Say the input data is a timeseries of electric field values sampled at
;1 sample/sec.
;Let's let dt = 10 sec and set let the minimum threshold = 2 mV/m.
;Pretend that the first 10 sec of Electric field data has 5 peaks
;greater than 2 mV/m, with the largest at 20 mV/m.
;For this first dt bin, the pk = 20 and npk = 5.

;NOTE that we could calculate %occurrence at this point, but instead we'll
;do this later when we sort these values by L and MLT. This allows us to plot
;%occurrence on a dial plot.


pro timeseries_reduce_to_pk_and_npk






;; Now that we have 1-D arrays for freq and amp of the FBK data we can divide
;; it up into discrete chunks so that we can save an entire mission's worth of data.

;;number of times with timestep dt
ntimes = n_elements(timesc)

t0 = freqs.x[0]
t1 = freqs.x[0] + info.dt

;;number of FBK spikes above threshold
peakn = fltarr(ntimes,nf_fce)
avgn = fltarr(ntimes,nf_fce)

;;peak values (peakv = peak channel; avgv = average channel) within each bin
peakv = fltarr(ntimes,nf_fce)
avgv = fltarr(ntimes,nf_fce)




;; amps_tmp_avg = amps_avg

;; goo = where(amps_tmp_avg[*] eq 0)
;; if goo[0] ne -1 then amps_tmp_avg[goo] = !values.f_nan ;Remove bad freqs from the amp array.
;; amplog_avg = alog10(amps_tmp_avg)

;; amps_tmp_avg4s = amps_avg4s
;; goo = where(amps_tmp_avg4s[*] eq 0)
;; if goo[0] ne -1 then amps_tmp_avg4s[goo] = !values.f_nan ;Remove bad freqs from the amp array.
;; amplog_avg4s = alog10(amps_tmp_avg4s)


;     freqs_tmp = freqs2/fce_eq  ;bad freqs already removed
;**     boo = where(finite(amps2) eq 0.)
;     boo = where(finite(amplitudes) eq 0.)
;     if boo[0] ne -1 then freqs_tmp[boo] = !values.f_nan ;Remove where amp outside of designated range



;;--------------------------------------------------
;;Histogram dummy runs to determine all the amplitude and
;;frequency bins...save each of these to a file
;;--------------------------------------------------


woo = HISTOGRAM(amplog[*,0],reverse_indices=ri,nbins=nbins,binsize=binsize,min=min(bins2),locations=loc)
ampbins = 10^loc

woo = HISTOGRAM(amplog_avg[*,0],reverse_indices=ri,nbins=nbins,binsize=binsize_avg,min=min(bins2_avg),$
                locations=loc)
ampbins_avg = 10^loc

woo = HISTOGRAM(amplog_ratio[*,0],reverse_indices=ri,nbins=nbins,binsize=binsize_ratio,min=min(bins2_ratio),$
                locations=loc)
ampbins_ratio = 10^loc


;; woo = HISTOGRAM(freqs_tmp,reverse_indices=ri,nbins=nbinsf,binsize=binsizef,min=min(binsf),locations=loc)
;; freqbins = loc


openw,lun3,info.path+'pk_bins.txt',/get_lun
printf,lun3,'amplitude bins for pk values'
for qq=0,n_elements(ampbins)-1 do printf,lun3,ampbins[qq]
close,lun3
free_lun,lun3

openw,lun3,info.path+'avg_bins.txt',/get_lun
printf,lun3,'amplitude bins for av values'
for qq=0,n_elements(ampbins_avg)-1 do printf,lun3,ampbins_avg[qq]
close,lun3
free_lun,lun3

openw,lun3,info.path+'ratio_bins.txt',/get_lun
printf,lun3,'amplitude bins for ratio values'
for qq=0,n_elements(ampbins_ratio)-1 do printf,lun3,ampbins_ratio[qq]
close,lun3
free_lun,lun3

openw,lun3,info.path+'freq_bins.txt',/get_lun
printf,lun3,'frequency bins'
for qq=0,n_elements(freqbins)-1 do printf,lun3,freqbins[qq]
close,lun3
free_lun,lun3


;;--------------------------------------------------
;;Now let's get the actual histogrammed values for each
;;time chunk dt
;;--------------------------------------------------


amphist_pk = fltarr(ntimes,nbins,nf_fce) ;for the amp histogram
amphist_avg = fltarr(ntimes,nbins,nf_fce)       ;...same but for average values
amphist_avg4s = fltarr(ntimes,nbins,nf_fce)     ;...same but for average values
amphist_ratio = fltarr(ntimes,nbins,nf_fce)     ;...same but for peak/average ratio
amphist_ratio4s = fltarr(ntimes,nbins,nf_fce)   ;...same but for peak/average ratio
;; freqhist = fltarr(ntimes,nbins,nf_fce)          ;for the freq histogram


for ntime=0d,ntimes-1 do begin
   ;;All data in timechunk dt
   tchunk = where((freqs.x ge t0) and (freqs.x le t1))

   if tchunk[0] ne -1 then begin
      for f=0,nf_fce-1 do begin


         print,'t0 = ' + time_string(t0)
         print,'t1 = ' + time_string(t1)
         print,'*****'

         ;;-----------------------------
         ;;Save the peak values each dt
         ;;-----------------------------


         boo = where(finite(amplitudes[tchunk,f]) ne 0 and finite(freqs2[tchunk]) ne 0,count)
         peakn[ntime,f] = count

         boo_avg = where(finite(amplitudes_avg[tchunk,f]) ne 0 and finite(freqs2[tchunk]) ne 0,count_avg)
         avgn[ntime,f] = count_avg


         if count ne 0 then begin
            tmp = amplitudes[tchunk[boo],f]
            peakv[ntime,f] = max(tmp,/nan)
         endif

         if count_avg ne 0 then begin
            tmp = amplitudes_avg[tchunk[boo_avg],f]
            avgv[ntime,f] = max(tmp,/nan)
         endif




         ;;peak values
         woo = where(finite(amplog[tchunk,f]) ne 0)
         if woo[0] ne -1 then amphist_pk[ntime,*,f] = HISTOGRAM(amplog[tchunk,f],reverse_indices=ri,nbins=nbins,$
                                                                   binsize=binsize,min=min(bins2),locations=loc)
         ;;average values (1/8s)
         woo = where(finite(amplog_avg[tchunk,f]) ne 0)
         if woo[0] ne -1 then amphist_avg[ntime,*,f] = HISTOGRAM(amplog_avg[tchunk,f],reverse_indices=ri,$
                                                               nbins=nbins,binsize=binsize_avg,$
                                                               min=min(bins2_avg),locations=loc)
         ;;average values (4s)
         woo = where(finite(amplog_avg4s[tchunk,f]) ne 0)
         if woo[0] ne -1 then amphist_avg4s[ntime,*,f] = HISTOGRAM(amplog_avg4s[tchunk,f],reverse_indices=ri,$
                                                                 nbins=nbins,binsize=binsize_avg,$
                                                                 min=min(bins2_avg),locations=loc)
         ;;peak/average ratio (using 1/8s avg values)
         woo = where(finite(amplog_ratio[tchunk,f]) ne 0)
         if woo[0] ne -1 then amphist_ratio[ntime,*,f] = HISTOGRAM(amplog_ratio[tchunk,f],reverse_indices=ri,$
                                                                 nbins=nbins,binsize=binsize_ratio,$
                                                                 min=min(bins2_ratio),locations=loc)
         ;;peak/average ratio (using 4s avg values)
         woo = where(finite(amplog_ratio4s[tchunk,f]) ne 0)
         if woo[0] ne -1 then amphist_ratio4s[ntime,*,f] = HISTOGRAM(amplog_ratio4s[tchunk,f],reverse_indices=ri,$
                                                                   nbins=nbins,binsize=binsize_ratio,$
                                                                   min=min(bins2_ratio),locations=loc)

      endfor
   endif

   t0 = t0 + info.dt
   t1 = t1 + info.dt

endfor







if testing then begin
   ;;MLT ranging from 0-12 and Lshell

   tinterpol_mxn,'rbspa_state_mlt',timesc,newname='rbspa_state_mlt'
   tinterpol_mxn,'rbspa_state_lshell',timesc,newname='rbspa_state_lshell'

   get_data,'rbspa_state_mlt',data=mlt
   mlt.y[*] = 5.  ;12d*dindgen(1440)/1439.
   store_data,'rbspa_state_mlt',data=mlt


   get_data,'rbspa_state_lshell',data=lshell
   lshell.y = (7-2)*indgen(1440)/1439. + 2.
   store_data,'rbspa_state_lshell',data=lshell

   tplot,'rbspa_state_'+['mlt','lshell']


   stop

;;**************************************************
;;***Test by artificially setting all the Lshell values of a SINGLE MLT
;;**************************************************

   ;; goo = where((lshell.y ge 2.) and (lshell.y lt 3.))
   ;; peakn[goo,4] = (60.*8*1.0)

   ;; goo = where((lshell.y ge 3.) and (lshell.y lt 4.))
   ;; peakn[goo,4] = (60.*8*0.9)
   ;; peakv[goo,4] = 2.

   ;; goo = where((lshell.y ge 4.) and (lshell.y lt 5.))
   ;; peakn[goo,4] = (60.*8*0.7)
   ;; peakv[goo,4] = 20.

   ;; goo = where((lshell.y ge 5.) and (lshell.y lt 6.))
   ;; peakn[goo,4] = (60.*8*0.5)
   ;; peakv[goo,4] = 50.

   ;; goo = where((lshell.y ge 6.) and (lshell.y lt 7.))
   ;; peakn[goo,4] = (60.*8*0.3)
   ;; peakv[goo,4] = 100.

;;**************************************************
;;***Test by artificially setting all the MLT values of a SINGLE Lshell
;;**************************************************
;;         goo = where((mlt.y ge 0.) and (mlt.y lt 1.))
;; ;;number of "dt" chunks
;; ;; RBSP_EFW> help,goo
;; ;; GOO             LONG      = Array[120]

;;         ;;In each of these "dt"s we want to see 60.*8 counts
;;         peakn[goo,4] = (60.*8*1.0)
;;         ;;this gives us a 100% duty cycle
;;         print,(60.*8)*(1/8.)/info.dt

;;         ;;Decrease duty cycle with each increasing MLT sector
;;         goo = where((mlt.y ge 1.) and (mlt.y lt 2.))
;;         peakn[goo,4] = (60.*8.*0.9)
;;         peakv[goo,4] = 2.
;;         goo = where((mlt.y ge 2.) and (mlt.y lt 3.))
;;         peakn[goo,4] = (60.*8.*0.8)
;;         peakv[goo,4] = 10.
;;         goo = where((mlt.y ge 3.) and (mlt.y lt 4.))
;;         peakn[goo,4] = (60.*8.*0.7)
;;         peakv[goo,4] = 20.
;;         goo = where((mlt.y ge 4.) and (mlt.y lt 5.))
;;         peakn[goo,4] = (60.*8.*0.6)
;;         peakv[goo,4] = 30.
;;         goo = where((mlt.y ge 5.) and (mlt.y lt 6.))
;;         peakn[goo,4] = (60.*8.*0.5)
;;         peakv[goo,4] = 40.
;;         goo = where((mlt.y ge 6.) and (mlt.y lt 7.))
;;         peakn[goo,4] = (60.*8.*0.4)
;;         peakv[goo,4] = 50.
;;         goo = where((mlt.y ge 7.) and (mlt.y lt 8.))
;;         peakn[goo,4] = (60.*8.*0.3)
;;         peakv[goo,4] = 60.
;;         goo = where((mlt.y ge 8.) and (mlt.y lt 9.))
;;         peakn[goo,4] = (60.*8.*0.2)
;;         peakv[goo,4] = 70.
;;         goo = where((mlt.y ge 9.) and (mlt.y lt 10.))
;;         peakn[goo,4] = (60.*8.*0.1)
;;         peakv[goo,4] = 80.
;;         goo = where((mlt.y ge 10.) and (mlt.y lt 11.))
;;         peakn[goo,4] = (60.*8.*0.05)
;;         peakv[goo,4] = 90.
;;         goo = where((mlt.y ge 11.) and (mlt.y lt 12.))
;;         peakn[goo,4] = (60.*8.*0.0)
;;         peakv[goo,4] = 100.



   stop

endif






;; ;**************************************************
;; ;testing the above arrays (all seems to work)
;; ;**************************************************

;;      if testing then begin


;; ;**************************************************
;; ;Test of peakv and avgv (note that total of the peak value in the
;; ;0.0*fce-10*fce bin should equal the total of the SINGLE peak value in
;; ;all the other bins)
;;         print,total(peakv[*,0])
;;         print,total(peakv[*,1]>peakv[*,2]>peakv[*,3]>peakv[*,4]>peakv[*,5]>peakv[*,6]>peakv[*,7]>peakv[*,8]>peakv[*,9]>peakv[*,10]>peakv[*,11])

;;         print,total(avgv[*,0])
;;         print,total(avgv[*,1]>avgv[*,2]>avgv[*,3]>avgv[*,4]>avgv[*,5]>avgv[*,6]>avgv[*,7]>avgv[*,8]>avgv[*,9]>avgv[*,10]>avgv[*,11])
;; ;**************************************************


;; ;**************************************************
;; ;Total number of counts in the 0*fce-10*fce bin should be equal to
;; ;                                      the total number of counts in
;; ;                                      all the other bins
;; ;                                      (e.g. 0*fce-0.1*fce +
;; ;                                      0.1*fce-0.2*fce...+1.0*fce-10.0*fce)
;;         print,total(peakn[*,0])
;;         print,total(peakn[*,1]+peakn[*,2]+peakn[*,3]+peakn[*,4]+peakn[*,5]+peakn[*,6]+peakn[*,7]+peakn[*,8]+peakn[*,9]+peakn[*,10]+peakn[*,11])

;;         print,total(avgn[*,0])
;;         print,total(avgn[*,1]+avgn[*,2]+avgn[*,3]+avgn[*,4]+avgn[*,5]+avgn[*,6]+avgn[*,7]+avgn[*,8]+avgn[*,9]+avgn[*,10]+avgn[*,11])
;; ;**************************************************


;; ;**************************************************
;; ;The amplitude arrays should also sum up properly

;;         print,total(amplog[*,0],/nan)
;;         sum = 0L
;;         for i=1,11 do sum += total(amplog[*,i],/nan)
;;         print,sum

;;         print,total(amplog_avg[*,0],/nan)
;;         sum = 0L
;;         for i=1,11 do sum += total(amplog_avg[*,i],/nan)
;;         print,sum

;;         print,total(amplog_avg4s[*,0],/nan)
;;         sum = 0L
;;         for i=1,11 do sum += total(amplog_avg4s[*,i],/nan)
;;         print,sum

;;         print,total(amplog_ratio[*,0],/nan)
;;         sum = 0L
;;         for i=1,11 do sum += total(amplog_ratio[*,i],/nan)
;;         print,sum

;;         print,total(amplog_ratio4s[*,0],/nan)
;;         sum = 0L
;;         for i=1,11 do sum += total(amplog_ratio4s[*,i],/nan)
;;         print,sum


;; ;**************************************************


;;         print,total(amphist_pk[*,*,0])
;;         print,total(amphist_pk[*,*,1]+amphist_pk[*,*,2]+amphist_pk[*,*,3]+amphist_pk[*,*,4]+amphist_pk[*,*,5]+amphist_pk[*,*,6]+amphist_pk[*,*,7]+amphist_pk[*,*,8]+amphist_pk[*,*,9]+amphist_pk[*,*,10]+amphist_pk[*,*,11])


;;         print,total(amphist_avg[*,*,0])
;;         print,total(amphist_avg[*,*,1]+amphist_avg[*,*,2]+amphist_avg[*,*,3]+amphist_avg[*,*,4]+amphist_avg[*,*,5]+amphist_avg[*,*,6]+amphist_avg[*,*,7]+amphist_avg[*,*,8]+amphist_avg[*,*,9]+amphist_avg[*,*,10]+amphist_avg[*,*,11])

;;         print,total(amphist_avg4s[*,*,0])
;;         print,total(amphist_avg4s[*,*,1]+amphist_avg4s[*,*,2]+amphist_avg4s[*,*,3]+amphist_avg4s[*,*,4]+amphist_avg4s[*,*,5]+amphist_avg4s[*,*,6]+amphist_avg4s[*,*,7]+amphist_avg4s[*,*,8]+amphist_avg4s[*,*,9]+amphist_avg4s[*,*,10]+amphist_avg4s[*,*,11])

;;         print,total(amphist_ratio[*,*,0])
;;         print,total(amphist_ratio[*,*,1]+amphist_ratio[*,*,2]+amphist_ratio[*,*,3]+amphist_ratio[*,*,4]+amphist_ratio[*,*,5]+amphist_ratio[*,*,6]+amphist_ratio[*,*,7]+amphist_ratio[*,*,8]+amphist_ratio[*,*,9]+amphist_ratio[*,*,10]+amphist_ratio[*,*,11])

;;         print,total(amphist_ratio4s[*,*,0])
;;         print,total(amphist_ratio4s[*,*,1]+amphist_ratio4s[*,*,2]+amphist_ratio4s[*,*,3]+amphist_ratio4s[*,*,4]+amphist_ratio4s[*,*,5]+amphist_ratio4s[*,*,6]+amphist_ratio4s[*,*,7]+amphist_ratio4s[*,*,8]+amphist_ratio4s[*,*,9]+amphist_ratio4s[*,*,10]+amphist_ratio4s[*,*,11])


;;         stop

;;      endif


;;Now that we're done using the high cadence Bfield data let's interpolate
;;it to the common times

sz = n_elements(timesc)/info.ndays
goo = strmid(time_string(timesc),0,10)
goo2 = strmid(time_string(freqs.x[0]),0,10)
goo = where(goo eq goo2)

tcurrent = timesc[goo]

fce = 28.*interpol(mag.y,mag.x,tcurrent)
fce_eq = interpol(fce_eq,pk.x,tcurrent)

tinterpol_mxn,rbspx+'_emfisis_l3_'+magcadence+'_gse_Mag',tcurrent,newname='Bfield'
get_data,'Bfield',data=Bfield


;;************
if keyword_set(test_mock_fbk7) then info.fbk_mode = '13'
;;************





f_fceBstr = strtrim(string(floor(10*info.f_fceB),format='(i8)'),2)
f_fceTstr = strtrim(string(floor(10*info.f_fceT),format='(i8)'),2)


;;---------------------------------------------------------
;;Save the peak and average values each dt to a file
;;---------------------------------------------------------

;;filenames will look like  fbk13_RBSPa_fbk0102_Ew_20121013.txt
goo = where(float(f_fceBstr) lt 10)
if goo[0] ne -1 then f_fceBstr[goo] = '0' + f_fceBstr[goo]
goo = where(float(f_fceTstr) lt 10)
if goo[0] ne -1 then f_fceTstr[goo] = '0' + f_fceTstr[goo]


currdate2 = strmid(time_string(time_double(currdate),format=2),0,8)





;;save the file with the ephemeris data
fnametmp = 'fbk'+info.fbk_mode+'_RBSP'+info.probe+'_fbk_ephem2_' + $
           info.fbk_type+'_'+currdate2+'.txt'

openw,lun,info.path + fnametmp,/get_lun
for zz=0L,ntimes-1 do printf,lun,format='(I10,5x,5f10.1,3f8.3)',$
                             tcurrent[zz],$
                             fce[zz],fce_eq[zz],$
                             Bfield.y[zz,0],Bfield.y[zz,1],Bfield.y[zz,2],$
                             sax[zz],say[zz],saz[zz]

;;save the peak and avg values, etc for each freq range
for f=0,nf_fce-1 do begin
   fnametmp = 'fbk'+info.fbk_mode+'_RBSP'+info.probe+'_fbk'+f_fceBstr[f]+f_fceTstr[f]+$
              '_'+info.fbk_type+'_'+currdate2+'.txt'

   openw,lun,info.path + fnametmp,/get_lun
   for zz=0L,ntimes-1 do printf,lun,format='(I10,5x,4f10.3)',$
                                tcurrent[zz],$
                                peakn[zz,f],avgn[zz,f],peakv[zz,f],avgv[zz,f]

endfor
close,lun
free_lun,lun


;;---------------------------------------------------------
;;Save the amplitude distributions to a file
;;---------------------------------------------------------
;;filenames will look like  fbk13_RBSPa_ampdist0102_Ew_20121013.txt

str = strtrim(n_elements(bins),2)
format = '(I10.5,5x,' + strtrim(n_elements(bins),2) + 'I5)'



if keyword_set(testing) then begin
   stop


   amphist_pk[*,0,1] = 1;./1440.
   amphist_pk[*,0,2] = 2;./1440.
   amphist_pk[*,0,3] = 3;./1440.
   amphist_pk[*,0,4] = 4;./1440.
   amphist_pk[*,0,5] = 5;./1440.

   amphist_pk[*,24,1] = 1;./1440.
   amphist_pk[*,24,2] = 2;./1440.
   amphist_pk[*,24,3] = 3;./1440.
   amphist_pk[*,24,4] = 4;./1440.
   amphist_pk[*,24,5] = 5;./1440.



endif


for i=0,nf_fce-1 do begin
   ;;Peak values
   fnametmp = 'fbk'+info.fbk_mode+'_RBSP'+info.probe+'_ampdist_pk'+f_fceBstr[i]+f_fceTstr[i]+$
              '_'+info.fbk_type+'_'+currdate2+'.txt'

   openw,lun,info.path + fnametmp,/get_lun
   for zz=0L,ntimes-1 do printf,lun,tcurrent[zz],amphist_pk[zz,*,i],format=format
   close,lun
   free_lun,lun


   ;;Average values (1/8s)
   fnametmp = 'fbk'+info.fbk_mode+'_RBSP'+info.probe+'_ampdist_avg'+f_fceBstr[i]+f_fceTstr[i]+$
              '_'+info.fbk_type+'_'+currdate2+'.txt'
   openw,lun,info.path + fnametmp,/get_lun
   for zz=0L,ntimes-1 do printf,lun,tcurrent[zz],amphist_avg[zz,*,i],format=format
   close,lun
   free_lun,lun


   ;;Average values (4s)
   fnametmp = 'fbk'+info.fbk_mode+'_RBSP'+info.probe+'_ampdist_avg4sec'+f_fceBstr[i]+f_fceTstr[i]+$
              '_'+info.fbk_type+'_'+currdate2+'.txt'
   openw,lun,info.path + fnametmp,/get_lun
   for zz=0L,ntimes-1 do printf,lun,tcurrent[zz],amphist_avg4s[zz,*,i],format=format
   close,lun
   free_lun,lun


   ;;Peak/Average ratio values (using 1/8s avg values)
   fnametmp = 'fbk'+info.fbk_mode+'_RBSP'+info.probe+'_ampdist_ratio'+f_fceBstr[i]+f_fceTstr[i]+$
              '_'+info.fbk_type+'_'+currdate2+'.txt'
   openw,lun,info.path + fnametmp,/get_lun
   for zz=0L,ntimes-1 do printf,lun,tcurrent[zz],amphist_ratio[zz,*,i],format=format
   close,lun
   free_lun,lun


   ;;Peak/Average ratio values (using 4s avg values)
   fnametmp = 'fbk'+info.fbk_mode+'_RBSP'+info.probe+'_ampdist_ratio4sec'+f_fceBstr[i]+f_fceTstr[i]+$
              '_'+info.fbk_type+'_'+currdate2+'.txt'
   openw,lun,info.path + fnametmp,/get_lun
   for zz=0L,ntimes-1 do printf,lun,tcurrent[zz],amphist_ratio4s[zz,*,i],format=format
   close,lun
   free_lun,lun



endfor

endif
end

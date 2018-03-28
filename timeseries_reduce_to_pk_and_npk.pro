;timeseries_reduce_to_pk_and_npk.pro

;Take an input timeseries of data and determine the number of
;times that the values are above a certain threshold in a
;time chunk of size "dt"

;Outputs a .txt file with the following variables:
;--peakv --> peak value in each timechunk
;--totalcounts --> number of data values (measurements) in each timechunk
;--totalcounts_above_threshold --> number of data values > threshold in each timechunk

; e.g. Say the input data is a timeseries of electric field values sampled at
; 1 sample/sec.
; Let's let dt = 10 sec and set let the minimum threshold = 2 mV/m.
; Pretend that the first 10 sec of Electric field data has 5 peaks
; greater than 2 mV/m, with the largest at 20 mV/m.
; For this first dt bin, the peakv = 20, totalcounts=10, totalcounts_above_threshold=5

; NOTE that we could calculate %occurrence at this point, but instead we'll
; do this later when we sort these values by L and MLT. This allows us to plot
; %occurrence on a dial plot.


pro timeseries_reduce_to_pk_and_npk,timeseries,dt,threshold

  get_data,timeseries,data=dat
  times = dat.x
  amps = dat.y


  ntimes = (max(dat.x,/nan)-min(dat.x,/nan))/dt  ;number of times with timestep dt

  totalcounts_above_threshold = fltarr(ntimes)  ;number of data counts in each time chunk above threshold
  totalcounts = fltarr(ntimes)   ;number of data counts in each time chunk 
  peakv = fltarr(ntimes)  ;peak value above threshold in each time chunk 



  ;--------------------------------------------------
  ;Now let's get the actual histogrammed values for each time chunk dt
  ;--------------------------------------------------

  times_center = fltarr(ntimes)
  goo = where(finite(times) ne 0.)


  t0 = times[goo[0]]
  t1 = times[goo[0]] + dt


  for ntime=0d,ntimes-1 do begin
    ;;All data in timechunk dt
    tchunk = where((times ge t0) and (times le t1))
    times_center[ntime] = (times[tchunk[0]] + times[tchunk[n_elements(tchunk)-1]])/2.

    if tchunk[0] ne -1 and finite(tchunk[0] ne 0.) then begin

      print,'t0 = ' + time_string(t0)
      print,'t1 = ' + time_string(t1)
      print,'*****'

      ;;Save the peak values, total counts, and total counts above threshold each dt
      boo = where(finite(amps[tchunk]) eq 1,count)
      totalcounts[ntime] = count
      goo = where(amps[tchunk] ge threshold,count)
      totalcounts_above_threshold[ntime] = count
        
      if count ne 0 then begin
        tmp = amps[tchunk[goo]]
        peakv[ntime] = max(tmp,/nan)
      endif

    endif
    t0 += dt
    t1 += dt
  endfor

  store_data,'peakv',times_center,peakv
  store_data,'totalcounts',times_center,totalcounts
  store_data,'totalcounts_above_threshold',times_center,totalcounts_above_threshold


;  fnametmp = 'test_histogram.txt'
;  openw,lun,'~/Desktop/' + fnametmp,/get_lun
;  printf,lun,'Centertime, Totalcounts>threshold, Totalcounts, PeakValue - for a threshold value of ' + strtrim(threshold,2)
;  for zz=0L,ntimes-1 do printf,lun,format='(I10,3x,4f10.3)',$
;    times_center[zz],$
;    totalcounts_above_threshold[zz],$
;    totalcounts[zz],$
;    peakv[zz]
;
;  close,lun
;  free_lun,lun
end

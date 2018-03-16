

;Crib sheet for testing timeseries_reduce_to_pk_and_npk.probe

rbsp_efw_init

path = '/Users/aaronbreneman/Desktop/Research/RBSP_hiss_precip2_coherence_survey/data/tplot_vars_2014/'
fn = 'IK.tplot'

tplot_restore,filenames=path + fn

get_data,'coh_IK_band0',data=d
d.v = d.v/1000.  ;Hz
periods = 1/d.v

;test at 0.1 Hz
periodtest = 14. ;minutes
periodtest *= 60.
tmpp = abs(periods - periodtest)
goo = min(tmpp,wh)
store_data,'test',d.x,d.y[*,wh]

dt = 1*3600.
threshold = 0.6
timeseries_reduce_to_pk_and_npk,'test',dt,threshold

copy_data,'peakv','IK_peakv'
copy_data,'totalcounts','IK_totalcounts'
copy_data,'totalcounts_above_threshold','IK_totalcounts_above_threshold'

tplot,'IK_'+['peakv','totalcounts','totalcounts_above_threshold']


tinterpol_mxn,'lshell_2I','peakv',newname='lshell_2I_interp'
tinterpol_mxn,'lshell_2K','peakv',newname='lshell_2K_interp'
tinterpol_mxn,'mlt_2I','peakv',newname='mlt_2I_interp'
tinterpol_mxn,'mlt_2K','peakv',newname='mlt_2K_interp'

;Find average L and MLT values
dif_data,'mlt_2I_interp','mlt_2K_interp'
get_data,'mlt_2I_interp',t1,d1
get_data,'mlt_2K_interp',t1,d2
store_data,'2IK_mltavg',t1,(d1+d2)/2.
get_data,'lshell_2I_interp',t1,d1
get_data,'lshell_2K_interp',t1,d2
store_data,'2IK_lshellavg',t1,(d1+d2)/2.


ylim,['mlt_2I_interp','mlt_2K_interp','2IK_mltavg'],0,24
tplot,['mlt_2I_interp','mlt_2K_interp','2IK_mltavg']
tplot,['lshell_2I_interp','lshell_2K_interp','2IK_lshellavg']


dlshell = 0.5                   ;delta-Lshell for grid	
lmin = 2
lmax = 7
dtheta = 1.                     ;delta-theta (hours) for grid
tmin = 0.
tmax = 24.
grid = return_L_MLT_grid(dtheta,dlshell,lmin,lmax,tmin,tmax)


pertime = percentoccurrence_L_MLT_calculate($
  dt,$
  'IK_totalcounts_above_threshold',$
  'IK_peakv',$
  '2IK_mltavg',$
  '2IK_lshellavg',grid=grid)


;values = pertime.percent_peaks
values = pertime.peaks
counts = pertime.counts


dial_plot,values,counts,grid


;; Returns variables needed to plot a grid pattern
;; Adds these as a structure to "info"


;; dtheta - delta MLT value for grid (hours)
;; dlshell - delta lshell value for grid
;; lmin, lmax - min and max Lshell values
;; tmin, tmax - min and max MLT (theta) values

;; Called from rbsp_survey_fbk_crib.pro


;; 	dtheta = 1.   ;delta-theta (hours) for grid
;; 	lmin = 2
;; 	lmax = 7
;;      tmin = 0.
;;      tmax = 24.  
;; 	dlshell = 0.4   ;delta-Lshell for grid




function return_L_MLT_grid,dtheta,dlshell,lmin,lmax,tmin,tmax

;; --------
;; Earth
;; --------

  rvals = replicate(1.,360)
  thetav = indgen(360.)

  Ex = rvals*cos(thetav*!dtor)
  Ey = rvals*sin(thetav*!dtor)

                                ;Shaded nightside
  boo = where(Ey gt 0.)
  Ey2 = Ey
  Ey2[boo] = 0.



;; ---------------------------------------
;; Create grid pattern
;; ---------------------------------------


;;Grid lines for theta
  grid_theta = (tmax-tmin)*indgen(1+(tmax-tmin)/dtheta)/((tmax-tmin)/dtheta) + tmin
  nthetas = n_elements(grid_theta)-1

;;Grid lines for Lshell
  grid_lshell = (lmax-lmin)*indgen(1+(lmax-lmin)/dlshell)/((lmax-lmin)/dlshell) + lmin
  nshells = n_elements(grid_lshell)-1



;;Define grid 
  grid_theta_rad = grid_theta*360/24.*!dtor


;;The middle point of each sector
  grid_lshell_center = grid_lshell[0:nshells-1] + dlshell/2.
  grid_theta_center = grid_theta[0:nthetas-1] + dtheta/2.



;;Add data to the info structure
  grid = {nthetas:nthetas,$
          nshells:nshells,$
          dtheta:dtheta,$
          lmin:lmin,$
          lmax:lmax,$
          dlshell:dlshell,$
          earthx:Ex,$
          earthy:Ey,$
          earthy_shade:Ey2,$
          grid_lshell:grid_lshell,$
          grid_theta:grid_theta,$
          grid_theta_rad:grid_theta_rad,$
          grid_theta_center:grid_theta_center,$
          grid_lshell_center:grid_lshell_center}
  
  

  return,grid

;  str_element,info,'grid',grid,/ADD_REPLACE


end



"""
Produce dial plots (e.g. L/MLT). Two plots. Typically left plot is observable 
and right is counts


"""


import sys 
sys.path.append('/Users/abrenema/Desktop/code/Aaron/github/signal_analysis/')
import numpy as np
import matplotlib.pyplot as plt



def draw_earth(ax,earth_resolution=50):
    """ Given a subplot object, draws the Earth with a shadow"""
    # Just x,y coords for a line (to map to polar coords)
    earth_circ = (np.linspace(0, 2*np.pi, earth_resolution), np.ones(earth_resolution)) 
    # x, y_lower, y_upper coords for Earth's shadow (maps to polar).
    earth_shadow = (
                    np.linspace(-np.pi/2, np.pi/2, earth_resolution), 
                    0, 
                    np.ones(earth_resolution)
                    )
    ax.plot(*earth_circ, c='k')
    ax.fill_between(*earth_shadow, color='k')
    return


def _plot_params(ax,L_labels):
    # Draw L shell contours and get L and MLT labels 
    L_labels_names = _draw_L_contours(ax,L_labels)
    mlt_labels = np.round(ax.get_xticks()*12/np.pi).astype(int)
    ax.set_xlabel('MLT')
    ax.set_theta_zero_location("S") # Midnight at bottom
    ax.set_xticks(mlt_labels*np.pi/12, labels=mlt_labels)
    ax.set_yticks(L_labels)
    ax.set_yticklabels(L_labels_names, fontdict={'horizontalalignment':'right'})
    return

def _draw_L_contours(ax,L_labels):
    """ Plots a subset of the L shell contours. """
    # Draw azimuthal lines for a subset of L shells.
    earth_resolution=50
    L_labels_names = [str(i) for i in L_labels[:-1]] + [f'L = {L_labels[-1]}']
    # L_labels_names = [str(i) for i in L_labels]
    for L in L_labels:
        ax.plot(np.linspace(0, 2*np.pi, earth_resolution), 
                    L*np.ones(earth_resolution), ls=':', c='k')
    return L_labels_names



#----------------------------
#Polar plots
#----------------------------

def dial_plot(vals, counts, angular_bins, radial_bins,
              mesh_kwargs1={'cmap':'viridis'},
              colorbar_kwargs1={'label':'plot 1', 'pad':0.1},
              mesh_kwargs2={'cmap':'viridis'},
              colorbar_kwargs2={'label':'plot 2', 'pad':0.1}):

    fig = plt.figure(figsize=(9, 4))
    ax = [plt.subplot(1, 2, i, projection='polar') for i in range(1, 3)]

    L_labels = [2,4,6]


    """
    Draws a dial plot on the self.ax subplot object (must have projection='polar' kwarg). 
    colorbar=True - Plot the colorbar or not.
    L_labels=[2,4,6,8] - What L labels to plot
    mesh_kwargs={} - The dictionary of kwargs passed to plt.pcolormesh() 
    colorbar_kwargs={} - The dictionary of kwargs passed into plt.colorbar()
    """
    #self.L_labels = L_labels
    # Turn off the grid to prevent a matplotlib deprecation warning 
    # (see https://matplotlib.org/3.5.1/api/prev_api_changes/api_changes_3.5.0.html#auto-removal-of-grids-by-pcolor-and-pcolormesh)
    ax[0].grid(False) 
    angular_grid, radial_grid = np.meshgrid(angular_bins, radial_bins)
    p = ax[0].pcolormesh(angular_grid*np.pi/12, radial_grid, vals, **mesh_kwargs1)
    plt.colorbar(p, ax=ax[0], **colorbar_kwargs1)
    draw_earth(ax[0])
    _plot_params(ax[0],L_labels)


    ax[1].grid(False) 
    p = ax[1].pcolormesh(angular_grid*np.pi/12, radial_grid, counts, **mesh_kwargs2)
    plt.colorbar(p, ax=ax[1], **colorbar_kwargs2)
    draw_earth(ax[1])
    _plot_params(ax[1],L_labels)




    for ax_i in ax:
        ax_i.set_rlabel_position(235)
        ax_i.tick_params(axis='y', colors='white')

#    plt.suptitle(f'SAMPEX-HILT | L-MLT map\n'+timeStrv+'\n'+Ptype + ' phase\n'+lcType + ' counts and number of samples')
    plt.tight_layout()
#    plt.savefig(save_path1,dpi=200)
    plt.show()
#    plt.close(fig)





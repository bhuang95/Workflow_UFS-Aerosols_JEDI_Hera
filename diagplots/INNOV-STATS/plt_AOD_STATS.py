import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
from matplotlib import gridspec
import matplotlib.dates as mdates
from matplotlib.dates import (DAILY, DateFormatter,
                            rrulewrapper, RRuleLocator)
from ndate import ndate
from datetime import datetime
from datetime import timedelta
import os, argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Print AOD and its hofx in obs space and their difference'
        )
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-i', '--stcycle',
        help="Cycle date in (YYYYMMDDTHH)",
        type=int, required=True)

    required.add_argument(
        '-j', '--edcycle',
        help="Cycle date in (YYYYMMDDTHH)",
        type=int, required=True)

    required.add_argument(
        '-e', '--nodaexp',
        help="Name of NODA experiment",
        type=str, required=True)

    required.add_argument(
        '-f', '--daexp',
        help="Name of NODA experiment",
        type=str, required=True)

    required.add_argument(
        '-s', '--spinupcnts',
        help="Cycle numners for spinup and not accounted in the mean calculation",
        type=int, required=True)

    args = parser.parse_args()
    cycst = args.stcycle
    cyced = args.edcycle
    nodaexp = args.nodaexp
    daexp = args.daexp
    spinupcnts = args.spinupcnts

    nodadir = nodaexp
    dadir = daexp

    field = 'cntlBkg'
    outfile = f'{nodadir}/{nodaexp}_{field}_nloc_mobs_mhfx_mbias_mmse_{cycst}_{cyced}.txt'
    datatmp = np.loadtxt(outfile)
    obs = datatmp[:,2]
    noda_hfx = datatmp[:,3]
    noda_bias = datatmp[:,4]
    noda_mse = datatmp[:,5]
    noda_rmse = np.sqrt(noda_mse)

    field = 'cntlBkg'
    outfile = f'{dadir}/{daexp}_{field}_nloc_mobs_mhfx_mbias_mmse_{cycst}_{cyced}.txt'
    datatmp = np.loadtxt(outfile)
    cntlbkg_hfx = datatmp[:,3]
    cntlbkg_bias = datatmp[:,4]
    cntlbkg_mse = datatmp[:,5]
    cntlbkg_rmse = np.sqrt(cntlbkg_mse)

    field = 'cntlAnl'
    outfile = f'{dadir}/{daexp}_{field}_nloc_mobs_mhfx_mbias_mmse_{cycst}_{cyced}.txt'
    datatmp = np.loadtxt(outfile)
    cntlanl_hfx = datatmp[:,3]
    cntlanl_bias = datatmp[:,4]
    cntlanl_mse = datatmp[:,5]
    cntlanl_rmse = np.sqrt(cntlanl_mse)

    field = 'emeanBkg'
    outfile = f'{dadir}/{daexp}_{field}_nloc_mobs_mhfx_mbias_mmse_{cycst}_{cyced}.txt'
    datatmp = np.loadtxt(outfile)
    emeanbkg_hfx = datatmp[:,3]
    emeanbkg_bias = datatmp[:,4]
    emeanbkg_mse = datatmp[:,5]
    emeanbkg_rmse = np.sqrt(emeanbkg_mse)

    field = 'emeanAnl'
    outfile = f'{dadir}/{daexp}_{field}_nloc_mobs_mhfx_mbias_mmse_{cycst}_{cyced}.txt'
    datatmp = np.loadtxt(outfile)
    emeananl_hfx = datatmp[:,3]
    emeananl_bias = datatmp[:,4]
    emeananl_mse = datatmp[:,5]
    emeananl_rmse = np.sqrt(emeananl_mse)

    aod=np.stack((obs, noda_hfx, cntlbkg_hfx, cntlanl_hfx, emeanbkg_hfx, emeananl_hfx), axis=1)
    bias=np.stack((noda_bias, cntlbkg_bias, cntlanl_bias, emeanbkg_bias, emeananl_bias), axis=1)
    rmse=np.stack((noda_rmse, cntlbkg_rmse, cntlanl_rmse, emeanbkg_rmse, emeananl_rmse), axis=1)
    mse=np.stack((noda_mse, cntlbkg_mse, cntlanl_mse, emeanbkg_mse, emeananl_mse), axis=1)

    maod=np.nanmean(aod[spinupcnts:,:], axis=0)
    mbias=np.nanmean(bias[spinupcnts:,:], axis=0)
    mrmse=np.nanmean(mse[spinupcnts:,:], axis=0)
    mrmse=np.sqrt(mrmse)
   
    leglist1=['VIIRS', 'FreeRun',  'DA-cntlBkg', 'DA-cntlAnl', 'DA-emBkg', 'DA-emAnl']
    leglist2=['FreeRun',  'DA-cntlBkg', 'DA-cntlAnl', 'DA-emBkg', 'DA-emAnl']
    pltcolor1=['gray', 'black', 'blue', 'red',  'green', 'darkorange']
    pltcolor2=['black', 'blue', 'red',  'green', 'darkorange']

    sdate=cycst
    edate=cyced
    inc_h=6
    sdate1=sdate #(sdate,-1.*inc_h)
    edate1=ndate(edate,inc_h)
    syy=int(str(sdate1)[:4]); smm=int(str(sdate1)[4:6])
    sdd=int(str(sdate1)[6:8]); shh=int(str(sdate1)[8:10])
    eyy=int(str(edate1)[:4]); emm=int(str(edate1)[4:6])
    edd=int(str(edate1)[6:8]); ehh=int(str(edate1)[8:10])

    date1 = datetime(syy,smm,sdd,shh)
    date2 = datetime(eyy,emm,edd,ehh)
    delta = timedelta(hours=inc_h)
    dates = mdates.drange(date1, date2, delta)

    rule = rrulewrapper(DAILY, byhour=0, interval=8)
    #rule = rrulewrapper(DAILY, count=8)
    loc = RRuleLocator(rule)
    formatter = DateFormatter('%Y %h %n %d %Hz')

    fig=plt.figure(figsize=(12, 10))
    gs = gridspec.GridSpec(3, 2, width_ratios=[3, 1]) 
    for ipt in range(0,6):
        print(ipt)
        ax=plt.subplot(gs[ipt])  #plt.subplot(3,1,ipt)
        #ax.set_prop_cycle(color=pltcolor, linestyle=pltstyle)
        if ipt==100:
           print('HBO')
        else:
            if ipt==0:
                data=aod
                title='(a) 550 nm AOD'
                ylab='AOD'
                pltcolor=pltcolor1
                leglist=leglist1
            elif ipt==1:
                data=maod
                title='(d) Mean AOD'
                pltcolor=pltcolor1
                leglist=leglist1
            elif ipt==2:
                data=bias
                title='(b) Bias against VIIRS 550 nm AOD'
                ylab='Bias'
                pltcolor=pltcolor2
                leglist=leglist2
            elif ipt==3:
                data=mbias
                title='(e) Mean AOD bias'
                pltcolor=pltcolor2
                leglist=leglist2
            elif ipt==4:
                data=rmse
                title='(c) RMSE against VIIRS 550 nm AOD'
                ylab='RMSE'
                pltcolor=pltcolor2
                leglist=leglist2
            elif ipt==5:
                data=mrmse
                title='(f) Mean AOD RMSE'
                ylab='RMSE'
                pltcolor=pltcolor2
                leglist=leglist2
    
            if np.mod(ipt, 2) == 0:
                ax.set_prop_cycle(color=pltcolor)
                ax.plot(dates,data, lw=2)
                ax.xaxis.set_major_formatter(formatter)
                ax.xaxis.set_tick_params(labelsize=12)
                ax.yaxis.set_tick_params(labelsize=12)
                ax.set_ylabel(ylab,fontsize=12)
                ax.grid(color='lightgrey', linestyle='--', linewidth=1)
                ax.set_title(title, loc='center',fontsize=14)
                if ipt==0:
                    ax.set_ylim(0.02, 0.32)
                    lgd=ax.legend(leglist, fontsize=12, loc='upper left', ncol=3, frameon=False)
                #lgd=ax.legend(leglist,fontsize=14, ncol=3, bbox_to_anchor=(0.5, -0.12), loc='upper center', frameon=False)
            else:
                print(leglist)
                print(data)
                ax.bar(leglist, data, color=pltcolor)
                ax.set_title(title, loc='center',fontsize=14)
                plt.xticks(rotation=270)
    fig.tight_layout()
    fig.savefig('aod_bias_rmse.png', format='png',bbox_inches='tight')

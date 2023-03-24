import sys,os,argparse
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
#from subprocess import check_output as chkop
import subprocess as sbps
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.dates import (DAILY, DateFormatter,
                              rrulewrapper, RRuleLocator)
from ndate import ndate
from datetime import datetime
from datetime import timedelta


def readFcstObsStats(filename,nlevs):
    fbar=np.zeros((1,nlevs),dtype='float')
    obar=np.zeros((1,nlevs),dtype='float')
    f=open(filename,'r')
    nlev=-1
    for line in f.readlines():
        if (nlev==-1):
            nlev=nlev+1
            continue
        else:
            fbar[0,nlev]=float(line.split()[25])
            obar[0,nlev]=float(line.split()[26])
            nlev=nlev+1
    f.close()
    return fbar, obar


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Plot aerosol vertical profiles'
        )
    )

    required = parser.add_argument_group(title='required arguments')

    required.add_argument(
        '-p', '--mask',
        help="Mask",
        type=str, required=True)

    required.add_argument(
        '-v', '--obsvar',
        help="Variable",
        type=str, required=True)

    required.add_argument(
        '-i', '--sdate',
        help="Starting cycle",
        type=int, required=True)

    required.add_argument(
        '-j', '--edate',
        help="Ending cycle",
        type=int, required=True)

    required.add_argument(
        '-a', '--dacntlpre',
        help="File prefix of AeroDA cntl",
        type=str, required=True)

    required.add_argument(
        '-b', '--daensmpre',
        help="File prefix of AeroDA ensm",
        type=str, required=True)
  
    required.add_argument(
        '-c', '--freerunpre',
        help="File prefix of FreeRun",
        type=str, required=True)

    args = parser.parse_args()
    sdate = args.sdate
    edate = args.edate
    mask = args.mask
    obsvar = args.obsvar
    dacntlpre = args.dacntlpre
    daensmpre = args.daensmpre
    freerunpre = args.freerunpre

    inc_h=6

    pregrps = [ freerunpre, dacntlpre, daensmpre ]

    ngrps=len(pregrps)
    leglist=["FreeRun 6h fcst", "AeroDACntl 6h fcst", "AeroDAEnsm 6h fcst", "AeroDACntl analysis", "AeroDAEnsm analysis"]
    pltcolor=['black', 'blue', 'green', 'red', 'orange']
    pltstyle=['-', '-','-','-','-']
    pltmarker=['o' ,'o', 'o','o','o']

    plev=(100, 250, 400, 500, 600, 700, 850, 925, 1000)
    #plev=(100, 150, 200, 250, 300, 400, 500, 600, 700, 800, 850, 900, 925, 950, 1000)

    tmpfile=f'{freerunpre}_{mask}_{sdate}.stat'
    f=open(tmpfile,'r')
    nlev=-1
    for line in f.readlines():
        nlev=nlev+1
    f.close()

    dlist=[]
    ntime=0
    cdate=sdate
    while (cdate<=edate):
        filename=f'{freerunpre}_{mask}_{cdate}.stat'
        ntime=ntime+1
        dlist.append(str(cdate))
        cdate=ndate(cdate,inc_h)

    fbar=np.zeros((ntime,nlev,ngrps),dtype='float')
    obar=np.zeros_like(fbar)
    pltdata=np.zeros((nlev,ngrps*2-1),dtype='float')

    ntime=0
    cdate=sdate
    while (cdate<=edate):
        for igrp in range(ngrps):
            filepre=pregrps[igrp]
            filename=f'{filepre}_{mask}_{cdate}.stat'
            fbar[ntime,:,igrp], obar[ntime,:,igrp]=readFcstObsStats(filename,nlev)

        cdate=ndate(cdate,inc_h)
        ntime=ntime+1
    print('get data')

# convert unit from kg/kg to ug/kg
    fbar=fbar*1.0E9
    obar=obar*1.0E9

#
# Plot data
#
    edate1=ndate(edate,inc_h)
    syy=int(str(sdate)[:4]); smm=int(str(sdate)[4:6])
    sdd=int(str(sdate)[6:8]); shh=int(str(sdate)[8:10])
    eyy=int(str(edate1)[:4]); emm=int(str(edate1)[4:6])
    edd=int(str(edate1)[6:8]); ehh=int(str(edate1)[8:10])

    date1 = datetime(syy,smm,sdd,shh)
    date2 = datetime(eyy,emm,edd,ehh)
    delta = timedelta(hours=inc_h)
    dates = mdates.drange(date1, date2, delta)

    rule = rrulewrapper(DAILY, byhour=0, interval=5)
    loc = RRuleLocator(rule)
    formatter = DateFormatter('%Y%h %n %d %Hz')

    print('get dates')

    print(leglist)

#  Vertical profile
#
#print([0:3])
    pltdata[:,0:ngrps]=fbar.mean(axis=0)
    pltdata[:,ngrps:]=obar[:,:,1:].mean(axis=0)

    print(pltdata)
    fig=plt.figure(figsize=(9,10))
    ax=plt.subplot()
    ax.invert_yaxis()
    ax.set_prop_cycle(color=pltcolor, linestyle=pltstyle, marker=pltmarker)
    ax.plot(pltdata,plev,lw=3.0, markersize=10)
    ax.tick_params(axis='both', labelsize=20)
    ax.legend(leglist, fontsize=24)
    ax.set_xlabel('Mixing Ratio [\u03bcg/kg]',fontsize=24)
    ax.set_ylabel('Pressure[hPa]',fontsize=24)
    ax.grid()
    ax.set_title(f'{mask} {obsvar}',loc='center', fontsize=18)

    fig.tight_layout()
    fig.savefig('VerticalProfile.png')

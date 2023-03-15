import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
import netCDF4 as nc
import numpy as np
from ndate import ndate
import os, argparse
#from datetime import datetime
#from datetime import timedelta


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
        '-a', '--aeroda',
        help="AeroDA or not",
        type=str, required=True)

    required.add_argument(
        '-m', '--emean',
        help="Plot for ensemble mean or not",
        type=str, required=True)

    required.add_argument(
        '-e', '--expname',
        help="Name of experiment",
        type=str, required=True)

    required.add_argument(
        '-d', '--topdatadir',
        help="Upper-level directory of expname",
        type=str, required=True)

    args = parser.parse_args()
    cycst = args.stcycle
    cyced = args.edcycle
    aeroda = (args.aeroda == "True" or args.aeroda == "true" or args.aeroda == "TRUE")
    emean = (args.emean == "True" or args.emean == "true" or args.emean == "TRUE")
    expname = args.expname
    datadir = args.topdatadir

    nancycs = [""]
    gmeta = "MetaData"
    gobs = "ObsValue"
    ghfx = "hofx"

    vlon = "longitude"
    vlat = "latitude"
    vobs = "aerosolOpticalDepth"
    vhfx = "aerosolOpticalDepth"

    print(f"HBO-{aeroda}-{emean}")
 
    fields=['cntlBkg']

    if aeroda:
        fields.append('cntlAnl')

    if emean:
        fields.append('emeanBkg')

    if emean and aeroda:
        fields.append('emeanAnl')

    #if emean:
    #    enkfpre =  "enkf"
    #    meanpre =  "ensmean"
    #else:
    #    enkfpre =  ""
    #    meanpre =  ""

    print(fields)
    for field in fields:

        if field in ['cntlBkg', 'emeanBkg']:
            trcr = 'fv_tracer'
        if field in ['cntlAnl', 'emeanAnl']:
            trcr = 'fv_tracer_aeroanl'

        if field in ['cntlBkg', 'cntlAnl']:
            enkfpre =  ""
            meanpre =  ""
        if field in ['emeanBkg', 'emeanAnl']:
            enkfpre =  "enkf"
            meanpre =  "ensmean"

        ncpre = f"NOAA_VIIRS_npp_obs_hofx_3dvar_LUTs_{trcr}"
        outfile = f"{expname}_{field}_nloc_mobs_mhfx_mbias_mmse_{cycst}_{cyced}.txt"
        
        print(outfile)

        cyc = cycst
        print(cyc)
        print(f'{expname}-{field}-{enkfpre}-{meanpre}')
        print(cyced)
        while cyc <= cyced:
            if cyc not in nancycs:
                cymd=str(cyc)[:8]
                ch=str(cyc)[8:]
                ncfile = f"{datadir}/{expname}/dr-data-backup/{enkfpre}gdas.{cymd}/{ch}/diag/{meanpre}/{ncpre}_{cyc}.nc4"
                print(ncfile)
                with nc.Dataset(ncfile, 'r') as ncdata:
                    #metagrp = ncdata.groups[gmeta]
                    obsgrp = ncdata.groups[gobs]
                    hfxgrp = ncdata.groups[ghfx]
                    #lontmp = metagrp[vlon][:]
                    #lattmp = metagrp[vlat][:]
                    obs = obsgrp[vobs][:,0]
                    hfx = hfxgrp[vhfx][:,0]
                    
                    nloc = len(obs)
                    bias = hfx - obs
                    bias2 = np.square(bias)
                    mobs = np.nanmean(obs) 
                    mhfx = np.nanmean(hfx) 
                    mbias = np.nanmean(bias) 
                    mmse = np.nanmean(bias2) 
            else:          
                nloc = len(obs)
                mobs = np.nan
                mhfx = np.nan
                mbias = np.nan 
                mmse = np.nan

            outdata = [cyc, nloc, mobs, mhfx, mbias, mmse]
            outdata_str =  ' '.join(str(i) for i in outdata)
            
            if cyc == cycst:
                with open(outfile, 'w') as f:
                    f.write(f'{outdata_str}\n')
            else:
                with open(outfile, 'a+') as f:
                    f.write(f'{outdata_str}\n')
            cyc = ndate(cyc, 6)

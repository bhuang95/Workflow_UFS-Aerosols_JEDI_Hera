#!/bin/bash
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -p service
##SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J ncks
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/ncks_merra2_camsira.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/ncks_merra2_camsira.out

module load nco

set -x 

ANL="MERRA2" 
#ANL="CAMSIRA"
ANLPRE="MERRA2_400.inst3_2d_gas_Nx." 
#ANLPRE="cams_aods_"
ANLSUF=".nc4" 
#ANLSUF=".nc"
OUTANLPRE="merra2" 
#UTANLPRE="camsira"
HOURS="00 06 12 18" # Dont change the elemen order of this variable.
SDATE=2017100700
EDATE=2017103100
CYCINC=24
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

#TOPINDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/MODEL/m2/akbkll
TOPINDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/MODEL/cams/pll_orig
TOPOUTDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/${ANL}/AOD

if [ ${ANL} = 'MERRA2' ]; then
    TIMEINDINC=2
elif [ ${ANL} = 'CAMSIRA' ]; then
    TIMEINDINC=1
else
    echo "Please define AODANL as MERRA2 or CAMSIRA. Exit"
    exit 1
fi

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    echo ${CDATE}
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}
    CYMD=${CDATE:0:8}
        
    INFILE=${TOPINDIR}/${ANLPRE}${CYMD}${ANLSUF}
    OUTDIR=${TOPOUTDIR}/${CY}/${CY}${CM}/${CY}${CM}${CD}
    [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}

    TIMEIND=0
    for HOUR in ${HOURS}; do
        OUTFILE=${OUTDIR}/${OUTANLPRE}_aods_${CYMD}${HOUR}_pll.nc
        [[ -f ${OUTFILE} ]] && rm -rf ${OUTFILE} 

        ncks -d time,${TIMEIND},${TIMEIND} ${INFILE} ${OUTFILE}
        #ncks -d time,0,0 ${INFILE} ${OUTFILE}
        ERR=$?
        [[ ${ERR} -ne 0 ]] && exit ${ERR}
	TIMEIND=$((${TIMEIND} + ${TIMEINDINC}))
    done
    CDATE=$(${NDATE} ${CYCINC} ${CDATE})
done

exit ${ERR}

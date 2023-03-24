#!/bin/bash
#SBATCH -n 1
#SBATCH -t 02:30:00
#SBATCH -p service
##SBATCH -q batch
#SBATCH -A chem-var
#SBATCH -J ncks
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/ncks_merra2_camsira.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/ncks_merra2_camsira.out

module load nco

set -x 

MANL="MERRA2"
CANL="CAMSIRA"

ANLS="${MANL} ${CANL}"

HOURS="00 06 12 18" # Dont change the elemen order of this variable.
SDATE=2017100600
EDATE=2017103100
CYCINC=24
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

for ANL in ${ANLS}; do
    TOPOUTDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/${ANL}/AOD
    if [ ${ANL} = ${MANL} ]; then
        ANLPRE="MERRA2_400.inst3_2d_gas_Nx." 
	ANLSUF=".nc4" 
	OUTANLPRE="merra2" 
	TIMEINDINC=2
        TOPINDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/MODEL/m2/akbkll
    elif [ ${ANL} = ${CANL} ]; then
	ANLPRE="cams_aods_"
	ANLSUF=".nc"
	OUTANLPRE="camsira"
	TIMEINDINC=1
        TOPINDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/MODEL/cams/pll_orig
    else
	echo "Please ANLPRE, ANLSUF, OUTANLPRE, TOPINDIR accordingly for your expeiments. Exit now"
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
            OUTFILE=${OUTDIR}/${OUTANLPRE}_aod_${CYMD}${HOUR}_ll.nc
            [[ -f ${OUTFILE} ]] && rm -rf ${OUTFILE} 

            ncks -d time,${TIMEIND},${TIMEIND} ${INFILE} ${OUTFILE}
            ERR=$?
            [[ ${ERR} -ne 0 ]] && exit ${ERR}
            TIMEIND=$((${TIMEIND} + ${TIMEINDINC}))
        done
        CDATE=$(${NDATE} ${CYCINC} ${CDATE})
    done
done
exit ${ERR}

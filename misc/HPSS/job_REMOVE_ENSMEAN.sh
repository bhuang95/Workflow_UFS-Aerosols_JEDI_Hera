#!/bin/bash --login
#SBATCH -J hpss2hera
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 23:59:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/hpss2hera.txt
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/hpss2hera.txt

module load hpss
#set -x

SDATE=2017100600
EDATE=2017102718
CINC=6
EXPNAME=AeroDA-1C192-20C192-201710
COMPONENT="atmos"
HERADIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/
HPSSDIR=/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/
TMPDIR=${HERADIR}/${EXPNAME}/dr-data-backup/REDO_HHSS2HERA_TMP
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    echo ${CDATE}
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}
    #HPSSFILE=${HPSSDIR}/${EXPNAME}/dr-data/${CY}/${CY}${CM}/${CY}${CM}${CD}/enkfgdas.${CDATE}.${COMPONENT}.ensmean.tar
    #TMPDATADIR=${TMPDIR}/${CDATE}
    HERADATADIR=${HERADIR}/${EXPNAME}/dr-data-backup/enkfgdas.${CY}${CM}${CD}/${CH}/${COMPONENT}/

    #[[ ! -d ${TMPDATADIR} ]] && mkdir -p ${TMPDATADIR}
    #[[ ! -d ${HERADATADIR} ]] && mkdir -p ${HERADATADIR}
    
    #cd ${TMPDATADIR}
    #rm -rf ensmean
    #htar -xvf ${HPSSFILE}
    #ERR=$?
    #if [ ${ERR} != 0 ]; then
    #    echo "${CDATE} failed"
    #	exit 1
    #else
    #    mv ensmean ${HERADATADIR}
    #	rm -rf ${TMPDATADIR}
    #fi
    rm -rf  ${HERADATADIR}/ensmean

    CDATE=$(${NDATE} ${CINC} ${CDATE})
done

exit ${ERR}

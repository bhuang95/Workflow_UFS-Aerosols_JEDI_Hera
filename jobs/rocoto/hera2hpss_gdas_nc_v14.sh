#! /usr/bin/env bash
##SBATCH -N 1
##SBATCH -t 00:30:00
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o ./bump_gfs_c96.out
##SBATCH -e ./bump_gfs_c96.out

module load hpss
set -x

export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
#export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
export CHGRESHPSSDIR=${CHGRESHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang//v14/"}
export CDATE=${CDATE:-"2017110100"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}
export NMEMSGRPS=${NMEMSGRPS:-"01-40"}

CYMD=${CDATE:0:8}
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDASDIR=${ROTDIR}
GDASCNTLOUT=${GDASDIR}/gdas.${CDATE}
GDASCNTLOUT1=${GDASDIR}/gdas.${CDATE}/OUTPUT_NC
GDASCNTLOUT2=${GDASDIR}/gdas.${CDATE}/OUTPUT_NC_CHGRES
GDASENKFOUT=${GDASDIR}/enkfgdas.${CDATE}
GDASENKFOUT1=${GDASDIR}/enkfgdas.${CDATE}/OUTPUT_NC
GDASENKFOUT2=${GDASDIR}/enkfgdas.${CDATE}/OUTPUT_NC_CHGRES

cd ${GDASCNTLOUT1}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
TARDIR=${CHGRESHPSSDIR}/GDAS_NC/${CY}/${CY}${CM}
TARFILE=gdas.${CDATE}.NC.tar
hsi "mkdir -p ${TARDIR}"
htar -cv -f ${TARDIR}/${TARFILE} *
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

cd ${GDASENKFOUT1}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
TARDIR=${CHGRESHPSSDIR}/ENKFGDAS_NC/${CY}/${CY}${CM}
TARFILE=enkfgdas.${CDATE}.NC.${NMEMSGRPS}.tar
hsi "mkdir -p ${TARDIR}"
htar -cv -f ${TARDIR}/${TARFILE} *
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

cd ${GDASCNTLOUT2}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
TARDIR=${CHGRESHPSSDIR}/GDAS_CHGRES_NC_${CASE_CNTL}/${CY}/${CY}${CM}
TARFILE=gdas.${CDATE}.${CASE_CNTL}.NC.tar
hsi "mkdir -p ${TARDIR}"
htar -cv -f ${TARDIR}/${TARFILE} *
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

cd ${GDASENKFOUT2}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
TARDIR=${CHGRESHPSSDIR}/ENKFGDAS_CHGRES_NC_${CASE_ENKF}/${CY}/${CY}${CM}
TARFILE=enkfgdas.${CDATE}.${CASE_ENKF}.NC.${NMEMSGRPS}.tar
hsi "mkdir -p ${TARDIR}"
htar -cv -f ${TARDIR}/${TARFILE} *
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

${NRM} ${GDASCNTLOUT}
${NRM} ${GDASENKFOUT}

exit ${ERR}

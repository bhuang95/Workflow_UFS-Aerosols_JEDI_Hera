#! /usr/bin/env bash
#SBATCH -N 1
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out


module load hpss

export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
export CHGRESHPSSDIR=${CHGRESHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/${PSLOT}/v14/"}
export CDATE=${CDATE:-"2017110100"}
CASE_CNTL=${CASE_CNTL:-"C192"}
CASE_ENKF=${CASE_ENKF:-"C192"}

CYMD=${CDATE:0:8}
CY=${CDATE:0:2}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDASCNTLOUT=${GDASDIR}/gdas.${CDATE}/OUTPUT
GDASENKFOUT=${GDASDIR}/enkfgdas.${CDATE}/OUTPUT


cd ${GDASCNTLOUT}
TARDIR=${CHGRESHPSSDIR}/${CASE_CNTL}/${CY}${CM}
TARFILE=gdas.${CDATE}.${CASE_CNTL}.tar
hsi "mkdir -p ${TARDIR}"
htar -cv -f ${TARDIR}/${TARFILE} *

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

cd ${GDASENKFOUT}
TARDIR=${CHGRESHPSSDIR}/${CASE_ENKF}/${CY}${CM}
TARFILE=enkfgdas.${CDATE}.${CASE_CNTL}.tar
hsi "mkdir -p ${TARDIR}"
htar -cv -f ${TARDIR}/${TARFILE} *

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

exit ${ERR}

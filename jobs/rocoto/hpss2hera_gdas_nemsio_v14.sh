#! /usr/bin/env bash
##SBATCH -n 1
##SBATCH -t 00:59:00
##SBATCH -p service
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
export GDASHPSSDIR=${GDASHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/BackupGdas/v14/"}
export CDATE=${CDATE:-"2017110100"}

CYMD=${CDATE:0:8}
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDASDIR=${ROTDIR}/
GDASCNTLIN=${GDASDIR}/gdas.${CDATE}/INPUT
GDASENKFIN=${GDASDIR}/enkfgdas.${CDATE}/INPUT

[[ ! -d ${GDASDIR} ]] && mkdir -p ${GDASDIR}
[[ ! -d ${GDASCNTLIN} ]] && mkdir -p ${GDASCNTLIN}
[[ ! -d ${GDASENKFIN} ]] && mkdir -p ${GDASENKFIN}

cd ${GDASCNTLIN}
TARFILE=${GDASHPSSDIR}/${CY}${CM}/gdas.${CDATE}.tar
htar -xvf ${TARFILE}

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

cd ${GDASENKFIN}
TARFILE=${GDASHPSSDIR}/${CY}${CM}/enkfgdas.${CDATE}.tar

rm -rf list1.gdasenkf list2.gdasenkf list3.gdasenkf

htar -tvf ${TARFILE} > list1.gdasenkf
grep mem00 list1.gdasenkf > list2.gdasenkf
grep mem01 list1.gdasenkf >> list2.gdasenkf
grep mem02 list1.gdasenkf >> list2.gdasenkf
grep mem03 list1.gdasenkf >> list2.gdasenkf
grep mem040 list1.gdasenkf >> list2.gdasenkf

while read -r line
do
    echo ${line##*' '} >> ./list3.gdasenkf
done < "./list2.gdasenkf"

htar -xvf ${TARFILE} -L ./list3.gdasenkf

#htar -xvf ${TARFILE}

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

exit ${ERR}

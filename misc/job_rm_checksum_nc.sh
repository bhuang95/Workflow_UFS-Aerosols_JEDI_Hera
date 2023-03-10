#!/bin/bash
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

DATA=$(pwd)
mkdir -p ${DATA}/RPLVARS
cd ${DATA}/RPLVARS
ITILE=1
COMIN_GES=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols//cycExp_ATMA_warm/dr-data/gdas.20171101/00/
COMPONENT=atmos
CYMD=20171101
CH=06

NCP="/bin/cp -r"
NLN="/bin/ln -sf"
RPLTRCRVARS="so4,bc1,bc2,oc1,oc2,dust1,dust2,dust3,dust4,dust5,seas1,seas2,seas3,seas4,seas5"
RPLEXEC=/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm//ush/python/replace_aeroanl_restart.py
while [[ ${ITILE} -le 6 ]]; do
    GESFILE=${COMIN_GES}/${COMPONENT}/RESTART/${CYMD}.${CH}0000.fv_tracer.res.tile${ITILE}.nc
    ANLFILE=${COMIN_GES}/${COMPONENT}/RESTART/${CYMD}.${CH}0000.fv_tracer_aeroanl.res.tile${ITILE}.nc
    ANLFILE_TMP=${COMIN_GES}/${COMPONENT}/RESTART/${CYMD}.${CH}0000.fv_tracer_aeroanl_tmp.res.tile${ITILE}.nc
    ${NCP} ${GESFILE} ${ANLFILE}
    ${NLN} ${ANLFILE_TMP} ./input.tile${ITILE}
    ${NLN} ${ANLFILE} ./output.tile${ITILE}
    #${NLN} ${GESFILE} ./ges.tile${ITILE}
    ITILE=$((ITILE+1))
done

echo ${RPLTRCRVARS} > INVARS.nml
${NCP} ${RPLEXEC} ./replace_aeroanl_restart.py

srun --export=all -n 1 python replace_aeroanl_restart.py -v INVARS.nml

ERR=$?
if  [ ${ERR} -ne 0 ]; then
    echo "ReplaceVars run failed and exit the program!!!"
    exit ${ERR}
#else
#    ${NRM} ${COMIN_GES}/${COMPONENT}/RESTART/${CYMD}.${CH}0000.fv_tracer_aeroanl_tmp.res.tile?.nc
fi

exit 0

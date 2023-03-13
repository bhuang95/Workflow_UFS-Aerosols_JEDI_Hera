#!/bin/bash

set -x

echo "Run FreeRun-1C192-0C192-201710"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-work-FreeRun-1C192-0C192-201710/FreeRun-1C192-0C192-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/FreeRun-1C192-0C192-201710/dr-work/FreeRun-1C192-0C192-201710.db

#echo "Run FreeRunSpinup-1C192-20C192-201710"
#/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-work-FreeRunSpinup-1C192-20C192-201710/FreeRunSpinup-1C192-20C192-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/FreeRunSpinup-1C192-20C192-201710/dr-work/FreeRunSpinup-1C192-20C192-201710.db

echo "Run CHGRES_V14"
/apps/rocoto/1.3.3/bin/rocotorun -w /home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-work-chgres/chgres_v14.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/CHGRES_V14GDAS/dr-work/chgres_v14.db

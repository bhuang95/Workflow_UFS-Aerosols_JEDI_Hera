#!/bin/bash

set -x

/apps/rocoto/1.3.3/bin/rocotostat -w /home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-work-FreeRunSpinup-1C192-20C192-201710/FreeRunSpinup-1C192-20C192-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/FreeRunSpinup-1C192-20C192-201710/dr-work/FreeRunSpinup-1C192-20C192-201710.db | less

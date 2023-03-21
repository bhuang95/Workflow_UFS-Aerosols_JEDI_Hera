#! /usr/bin/env bash
#SBATCH -N 1
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out


export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}

source "${EXPDIR}/config.base" 

export DATAROOT=${DATAROOT:-"$(pwd)"}
export job="echgres"
export jobid="${job}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}

export CDATE=${CDATE:-"2017110100"}
export LEVS=${LEVS:-"128"}
export ENSGRP=${ENSGRP:-"01"}
export NMEM_EFCSGRP=${NMEM_EFCSGRP:-"5"}


ENSED=$((NMEM_EFCSGRP * ${ENSGRP}))
if [ ${ENSGRP} = "01" ]; then
    ENSST=0
else
    ENSST=$((ENSED - NMEM_EFCSGRP + 1))
fi
CYMD=${CDATE:0:8}
CY=${CDATE:0:2}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDASCNTLIN=${GDASDIR}/gdas.${CDATE}/INPUT
GDASCNTLOUT=${GDASDIR}/gdas.${CDATE}/OUTPUT
GDASENKFIN=${GDASDIR}/enkfgdas.${CDATE}/INPUT
GDASENKFOUT=${GDASDIR}/enkfgdas.${CDATE}/OUTPUT

[[ ! -d ${GDASCNTLIN} ]] && mkdir -p ${GDASCNTLIN}
[[ ! -d ${GDASCNTLOUT} ]] && mkdir -p ${GDASCNTLOUT}
[[ ! -d ${GDASENKFIN} ]] && mkdir -p ${GDASENKFIN}
[[ ! -d ${GDASENKFOUT} ]] && mkdir -p ${GDASENKFOUT}

#Run NEMSIO2NC
echo "STEP-1: Run NEMSIO2NC"
NEMSIO2NCDIR=${DATA}/NEMSIO2NC
mkdir -p ${NEMIO2NCDIR}
cd ${NEMISO2NCDIR}

# Variable for nemsio2nc
NEMSIO2NCEXEC=${HOMEgfs}/exec/nemsioatm2nc
module use ${HOMEgfs}/modulefiles
module load hera.gnu
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

${NLN} ${NEMSIO2NCEXEC} ./nemsion2nc 

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    ${NRM} ${NEMSIO2NCDIR}/input.nemsio
    ${NRM} ${NEMSIO2NCDIR}/output.nc
    MEMSTR="mem"`printf %03d ${IMEM}`

    if [ ${IMEM} -eq 0 ]; then
        INFILE=${GDASCNTLIN}/gdas.t${CH}z.atmanl.${MEMSTR}.nemsio
        OUTFILE=${GDASECNTLIN}/gdas.t${CH}z.atmanl.${MEMSTR}.nc
    else
        INFILE=${GDASENKFIN}/${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.nemsio
        OUTFILE=${GDASENKFIN}/${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.nc
    fi
    ${NLN} ${INFILE} ${DATA}/input.nemsio
    ${NLN} ${OUTFILE} ${DATA}/output.nc

    srun --export=all -n 1 nemsio2nc input.nemsio output.nc

    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    echo "${MEMSTR} NEMSIO2NC completed."
    IMEM=$((IMEM+1))
done

#Run CHGRES for atmanl
echo "STEP-2: Convert atmanl nc resolution"
ATMANLDIR=${DATA}/ATMANLDIR
mkdir -p ${ATMANLDIR}
cd ${ATMANLDIR}

# Variable for chgres atmanl
CHGRESNCEXEC=${HOMEgfs}/exec/enkf_chgres_recenter_nc.x
CASE_CNTL=${CASE_CNTL:-"C192"}
CASE_ENKF=${CASE_ENKF:-"C192"}
REFFILE=${REFFILE:-""}

module purge
source "${HOMEgfs}/ush/preamble.sh"
# Source FV3GFS workflow modules
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh

${NLN} ${CHGRESNCEXEC} ./enkf_chgres_recenter_nc.x

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    ${NRM} ${ATMANLDIR}/input.nc
    ${NRM} ${ATMANLDIR}/output.nc
    ${NRM} ${ATMANLDIR}/chgres_nc_gauss.nml
    MEMSTR="mem"`printf %03d ${IMEM}`

    if [ ${IMEM} -eq 0 ]; then
        RES=${CASE_CNTL:1:4}
        INFILE=${GDASCNTLIN}/gdas.t${CH}z.atmanl.nc
        OUTFILE=${GDASCNTLOUT}/gdas.t${CH}z.atmanl.${CASE_CNTL}.nc
    else
        RES=${CASE_ENKF:1:4}
        INFILE=${GDASENKFIN}/${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.nc
        OUTFILE=${GDASENKFOUT}/${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.${CASE_ENKF}.nc
	mkdir -p ${GDASENKFOUT}/${MEMSTR}/
    fi

    LONB=$((4*RES))
    LATB=$((2*RES))

    ${NLN} ${INFILE} ${ATMANLDIR}/input.nc
    ${NLN} ${OUTFILE} ${ATMANLDIR}/output.nc
cat > chgres_nc_gauss.nml << EOF
&chgres_setup
i_output=$LONB
j_output=$LATB
input_file="input.nc"
output_file="output.nc"
terrain_file="ref.nc"
ref_file="ref.nc"
/
EOF

    srun -n 1 enkf_chgres_recenter_nc.x  chgres_nc_gauss.nml
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    echo "${MEMSTR} ATMANL_CHGRES completed."
    IMEM=$((IMEM+1))
done

#Run chgres_cube for sfcanl file
SFCANLDIR=${DATA}/SFCANL
mkdir -p ${SFCANLDIR}
cd ${SFCANLDIR}


# Variable for chgres sfcanl
CHGRESCUBE=${HOMEgfs}/exec/chgres_cube
FIX_FV3=${HOMEgfs}/fix
FIX_ORO=${FIX_FV3}/orog
FIX_AM=${FIX_FV3}/am

${NLN} ${CHGRESCUBE} ./chgres_cube

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    ${NRM} ${SFCANLDIR}/fort.41
    ${NRM} ${SFCANLDIR}/*.nemsio
    ${NRM} ${SFCANLDIR}/*.nc
    MEMSTR="mem"`printf %03d ${IMEM}`

    if [ ${IMEM} -eq 0 ]; then
        CTAR=${CASE_CNTL}
        ATMFILE=${GDASCNTLIN}/gdas.t${CH}z.atmanl.${MEMSTR}.nc
        SFCFILE=${GDASCNTLIN}/gdas.t${CH}z.sfcanl.${MEMSTR}.nc
        NSTFILE=${GDASCNTLIN}/gdas.t${CH}z.nstanl.${MEMSTR}.nc
	OUTDIR=${GDASCNTLOUT}/RESTART/
    else
        CTAR=${CASE_ENKF}
        ATMFILE=${GDASENKFIN}/${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.nc
        SFCFILE=${GDASENKFIN}/${MEMSTR}/gdas.t${CH}z.sfcanl.${MEMSTR}.nc
        NSTFILE=${GDASENKFIN}/${MEMSTR}/gdas.t${CH}z.nstanl.${MEMSTR}.nc
	OUTDIR=${GDASENKFOUT}/${MEMSTR}/RESTART/
    fi

    mkdir -p ${OUTDIR}
    ${NLN} ${ATMFILE} ${SFCDIR}/atm.nemsio
    ${NLN} ${SFCFILE} ${SFCDIR}/sfc.nemsio
    ${NLN} ${NSTFILE} ${SFCDIR}/nst.nemsio

cat << EOF > fort.41
&config
 fix_dir_target_grid="${FIX_ORO}/${CTAR}/fix_sfc"
 mosaic_file_target_grid="${FIX_ORO}/${CTAR}/${CTAR}_mosaic.nc"
 orog_dir_target_grid="${FIX_ORO}/${CTAR}"
 orog_files_target_grid="${CTAR}_oro_data.tile1.nc","${CTAR}_oro_data.tile2.nc","${CTAR}_oro_data.tile3.nc","${CTAR}_oro_data.tile4.nc","${CTAR}_oro_data.tile5.nc","${CTAR}_oro_data.tile6.nc"
 data_dir_input_grid="${SFCDIR}"
 atm_files_input_grid="atm.nemsio"
 sfc_files_input_grid="sfc.nemsio"
 nst_files_input_grid="nst.nemsio"
 vcoord_file_target_grid="${FIX_AM}/global_hyblev.l${LEVS}.txt"
 cycle_mon=${CM}
 cycle_day=${CD}
 cycle_hour=${CH}
 convert_atm=.false.
 convert_sfc=.true.
 convert_nst=.true.
 input_type="gfs_gaussian_nemsio"
 tracers="sphum","liq_wat","o3mr"
 tracers_input="spfh","clwmr","o3mr"
/
EOF

srun chgres_cube
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    echo "${MEMSTR} completed."
    for tile in 'tile1' 'tile2' 'tile3' 'til4' 'tile5' 'tile6'; do
        ${NMV} out.sfc.${tile}.nc ${OUTDIR}/${CYMD}.${CH}0000.sfcanl_data.${tile}.nc
        ERR=$?
        [[ ${ERR} -ne 0 ]] && exit ${ERR}
    done

    IMEM=$((IMEM+1))
done


exit 0

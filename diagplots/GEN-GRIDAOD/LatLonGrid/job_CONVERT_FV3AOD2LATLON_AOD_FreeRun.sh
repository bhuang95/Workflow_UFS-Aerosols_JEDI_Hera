#!/bin/bash
#SBATCH -n 1
#SBATCH -t 01:30:00
##SBATCH -p batch
#SBATCH -q batch
#SBATCH -A chem-var
#SBATCH -J fvaodtolatlon
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/fvaod2latlon_freerun.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/fvaod2latlon_freerun.out

set -x

TMPDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/
FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"
EXPNAMES="${FREERUNEXP}"
SDATE=2017100600
EDATE=2017102718
CYCINC=6
TOPRUNDIR=${TOPRUNDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/"}
OUTAODDIR=${OUTAODDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/FV3/AOD"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}
FIXDIR_SELF=${FIXDIR_SELF:-"${HOMEgfs}/fix_self"}
CASE=${CASE:-"C192"}
DATA=${DATA:-${TMPDIR}/fv2latlon_freerun}
AODTYPE=${AODTYPE:-"NOAA_VIIRS"}
COMPONENT=${COMPONENT:-"atmos"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
FV2LATLONEXEC=${FV2LATLONEXEC:-${HOMEgfs}/exec/fv3aod2ll.x}
NCORES=40

#Load modules
source ${HOMEjedi}/jedi_module_base.hera.sh
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/libs/fortran-datetime/lib"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1

# Determine sensor ID
if [ $AODTYPE = "NOAA_VIIRS" ]; then
    #sensorIDs="v.viirs-m_npp v.viirs-m_j1"
    sensorIDs="v.viirs-m_npp"
elif [ $AODTYPE = "MODIS-NRT" ]; then
    sensorIDs="v.modis_terra v.modis_aqua"
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

[[ ! -d ${DATA} ]] && mkdir -p ${DATA}
cd ${DATA}

# Link executables to working director
echo ${FV2LATLONEXEC}
rm -rf ./fv3aod2ll.x
${NCP} ${FV2LATLONEXEC} ./fv3aod2ll.x

for EXPNAME in ${EXPNAMES}; do
    if [ ${EXPNAME} = ${FREERUNEXP} ]; then
        TRCRS="fv_tracer"
    else
        TRCRS="fv_tracer  fv_tracer_aeroanl"
    fi

    CDATE=${SDATE}
    while [ ${CDATE} -le ${EDATE} ]; do
        CYMD=${CDATE:0:8}
        CY=${CDATE:0:4}
        CM=${CDATE:4:2}
        CD=${CDATE:6:2}
        CH=${CDATE:8:2}
        CDATEPRE="${CYMD}.${CH}0000"

        INDIR=${TOPRUNDIR}/${EXPNAME}/dr-data-backup/gdas.${CYMD}/${CH}/diag/FV3_AOD/

        
        for TRCR in ${TRCRS}; do
            if [ ${TRCR} = "fv_tracer" ]; then
                FIELD="cntlBkg"
            elif  [ ${TRCR} = "fv_tracer_aeroanl" ]; then
                FIELD="cntlAnl"
	    else
		echo "Please check your tracer name, fv_tracer or fv_tracer_aeroanl and exit now"
		exit 1
            fi

            OUTDIR=${OUTAODDIR}/${EXPNAME}/${FIELD}/${CY}/${CY}${CM}/${CY}${CM}${CD}
            [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
            for isensorID in ${sensorIDs}; do
	        INAOD=${CDATEPRE}.fv_aod_LUTs_${isensorID}.${TRCR}.res.tile?.nc
	        OUTAOD=fv3_aod_${isensorID}_${CDATE}_ll.nc

[[ -f fv3aod2ll.nl ]] && rm -rf fv3aod2ll.nl
cat > fv3aod2ll.nl <<EOF
&record_input
 date="${CDATE}"
 input_grid_dir="${FIXDIR_SELF}/grid_spec/${CASE}"
 fname_grid="${CASE}_grid_spec.tile?.nc"
 input_fv3_dir="${INDIR}"
 fname_fv3="${INAOD}"
/
&record_interp
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${OUTDIR}"
 fname_aod_ll="${OUTAOD}"
/
EOF

#srun --export=all -n ${NCORES}  ./fv3aod2ll.x
./fv3aod2ll.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "fv3aod2ll.x failed an exit!!!"
    exit 1
fi

done # end of isensorID-loop
done # end of TRCR-loop

CDATE=$(${NDATE} ${CYCINC} ${CDATE})
done # end of CDATE-loop
done # end of EXPNAME-loop
### 
###############################################################
# Postprocessing
#cd $pwd
[[ $ERR -eq 0 ]] && rm -rf $DATA

#set +x
#if [ $VERBOSE = "YES" ]; then
#   echo $(date) EXITING $0 with return code $err >&2
#fi
exit ${ERR}

#!/bin/bash
#SBATCH -N 1
#SBATCH -t 00:30:00
##SBATCH -p hera
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/calc_fv3grid_aod_cntl.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/calc_fv3grid_aod_cntl.out

TMPDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/FV3AOD/"
FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"
EXPNAMES="${FREERUNEXP}"
#EXPNAMES="${AERODAEXP}"
SDATE=2017102500
EDATE=2017102718
CYCINC=6
TOPRUNDIR=${TOPRUNDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}
DATA=${DATA:-${TMPDIR}/gocart_aod_fv3_mpi_cntl}
AODTYPE=${AODTYPE:-"NOAA_VIIRS"}
COMPONENT=${COMPONENT:-"atmos"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
AODEXEC=${AODEXEC:-${HOMEgfs}/exec/gocart_aod_fv3_mpi_LUTs.x}
NCORES=40

#Load modules
source ${HOMEjedi}/jedi_module_base.hera.sh
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
${NLN} $AODEXEC ./gocart_aod_fv3_mpi_LUTs.x
${NLN} ${HOMEjedi}/geos-aero/test/testinput/geosaod.rc ./geosaod.rc
${NLN} ${HOMEjedi}/geos-aero/test/testinput/Chem_MieRegistry.rc ./Chem_MieRegistry.rc
${NLN} ${HOMEjedi}/geos-aero/test/Data ./
${NLN} ${HOMEgfs}/nasaluts/all_wavelengths.rc ./

for EXPNAME in ${EXPNAMES}; do
    if [ ${EXPNAME} = ${FREERUNEXP} ]; then
        TRCRS="fv_tracer"
    else
        TRCRS="fv_tracer  fv_tracer_aeroanl"
    fi

    CDATE=${SDATE}
    while [ ${CDATE} -le ${EDATE} ]; do
        CYMD=${CDATE:0:8}
        CH=${CDATE:8:2}
        CDATEPRE="${CYMD}.${CH}0000"

        GDATE=$(${NDATE} -${CYCINC} ${CDATE})
        GYMD=${GDATE:0:8}
        GH=${GDATE:8:2}
        
        INDATADIR=${TOPRUNDIR}/${EXPNAME}/dr-data-backup/gdas.${GYMD}/${GH}/atmos/RESTART/
        OUTDATADIR=${TOPRUNDIR}/${EXPNAME}/dr-data-backup/gdas.${CYMD}/${CH}/diag/FV3_AOD/

        [[ ! -d ${OUTDATADIR} ]] && mkdir -p ${OUTDATADIR}
        
        for TRCR in ${TRCRS}; do
            for isensorID in ${sensorIDs}; do
                FAKBK=${CDATEPRE}.fv_core.res.nc
                for itile in $(seq 1 6); do
                    FCORE=${CDATEPRE}.fv_core.res.tile${itile}.nc
                    FTRACER=${CDATEPRE}.${TRCR}.res.tile${itile}.nc
	            FAOD=${CDATEPRE}.fv_aod_LUTs_${isensorID}.${TRCR}.res.tile${itile}.nc

[[ -f ${DATA}/gocart_aod_fv3_mpi.nl ]] && ${NRM} ${DATA}/gocart_aod_fv3_mpi.nl
cat << EOF > ${DATA}/gocart_aod_fv3_mpi.nl 	
&record_input
 input_dir = "${INDATADIR}"
 fname_akbk = "${FAKBK}"
 fname_core = "${FCORE}"
 fname_tracer = "${FTRACER}"
 output_dir = "${OUTDATADIR}"
 fname_aod = "${FAOD}"
/
&record_model
 Model = "AodLUTs"
/
&record_conf_crtm
 AerosolOption = "aerosols_gocart_default"
 Absorbers = "H2O","O3"
 Sensor_ID = "${isensorID}"
 EndianType = "big_endian"
 CoefficientPath = ${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/
 Channels = 4
/
&record_conf_luts
 AerosolOption = "aerosols_gocart_2"
 WavelengthsOutput = 380.,500.,550.,870
 RCFile = "all_wavelengths.rc"
/
EOF
cat gocart_aod_fv3_mpi.nl  
srun --export=all -n ${NCORES}  ./gocart_aod_fv3_mpi_LUTs.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "gocart_aod_fv3_mpi_LUTs failed an exit!!!"
    exit 1
#else
#    /bin/rm -rf ${DATA}/gocart_aod_fv3_mpi.nl
fi
done # end of itile-loop
done # end of isensorID-loop
done # end of TRCR-loop
CDATE=$(${NDATE} ${CYCINC} ${CDATE})
done # end of CDATE-loop
done # end of EXPNAME-loop
### 
###############################################################
# Postprocessing
[[ ${ERR} -eq 0 ]] && rm -rf $DATA

#set +x
#if [ $VERBOSE = "YES" ]; then
#   echo $(date) EXITING $0 with return code $err >&2
#fi
exit ${ERR}

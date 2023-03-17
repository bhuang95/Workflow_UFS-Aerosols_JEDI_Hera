#!/bin/bash
#SBATCH -N 1
#SBATCH -t 00:30:00
##SBATCH -p batch
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

TMPDIR=`pwd`
FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"
EXPNAMES="${FREERUNEXP} ${AERODAEXP}"
SDATE=2017100600
EDATE=2017100618
CYCINC=6
TOPRUNDIR=${TOPRUNDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}
FIXDIR_SELF=${FIXDIR_SELF:-"${HOMEgfs}/fix_self"}
CASE=${CASE:-"C192"}
DATA=${DATA:-${TMPDIR}/gocart_aod_fv3_mpi.$$}
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

        INDATADIR=${TOPRUNDIR}/${EXPNAME}/dr-data-backup/gdas.${CYMD}/${CH}/diag/FV3_AOD/

        [[ ! -d ${OUTDATADIR} ]] && mkdir -p ${OUTDATADIR}
        
        for TRCR in ${TRCRS}; do
            if [ ${TRCR} = "fv_tracer" ]; then
                FIELD="cntlBkg"
            elif  [ ${TRCR} = "fv_tracer_aeroanl" ]; the
                FIELD="cntlAnl"
	    else
		echo "Please check your tracer name, fv_tracer or fv_tracer_aeroanl and exit now"
		exit 1
            fi
            for isensorID in ${sensorIDs}; do
	        FAOD=${CDATEPRE}.fv_aod_LUTs_${isensorID}.${TRCR}.res.tile?.nc

[[ -f fv3aod2ll.nl ]] && rm -rf fv3aod2ll.nl
cat > fv3aod2ll.nl <<EOF
&record_input
 date="${CDATE}"
 input_grid_dir="${FIXDIR_SELF}/grid_spec/${CASE}"
 fname_grid="${CASE}_grid_spec.tile?.nc"
 input_fv3_dir="${INDIR}"
 fname_fv3="${FAOD}"
/
&record_interp
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${OUTDIR}"
 fname_aod_ll="${OUTFILE}"
/
EOF

cat gocart_aod_fv3_mpi.nl  
srun --export=all -n ${NCORES}  ./gocart_aod_fv3_mpi_LUTs.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "gocart_aod_fv3_mpi_LUTs failed an exit!!!"
    exit 1
else
    /bin/rm -rf ${DATA}/gocart_aod_fv3_mpi.nl
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
#cd $pwd
#[[ $mkdata = "YES" ]] && rm -rf $DATA

#set +x
#if [ $VERBOSE = "YES" ]; then
#   echo $(date) EXITING $0 with return code $err >&2
#fi
exit ${ERR}

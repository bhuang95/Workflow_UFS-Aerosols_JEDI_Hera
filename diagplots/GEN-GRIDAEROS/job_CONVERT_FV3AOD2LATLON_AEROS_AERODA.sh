#!/bin/bash
#SBATCH -N 1
#SBATCH -t 00:30:00
##SBATCH -p batch
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fvaerotolatlon_AeroDA
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/fvaero2latlon_AeroDA.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/fvaero2latlon_AeroDA.out

set -x


TMPDIR=`pwd`
FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"
TMPDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/GRID-AERO/${AERODAEXP}"
EXPNAMES="${AERODAEXP}"
SDATE=2017102312
EDATE=2017102318
CYCINC=6
TOPRUNDIR=${TOPRUNDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/"}
OUTAEROSDIR=${OUTAEROSDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/FV3/AEROS"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}
FIXDIR_SELF=${FIXDIR_SELF:-"${HOMEgfs}/fix_self"}
CASE=${CASE:-"C192"}
DATA=${DATA:-${TMPDIR}/fv2latlon_aeros}
COMPONENT=${COMPONENT:-"atmos"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
FV2LATLONEXEC=${FV2LATLONEXEC:-${HOMEgfs}/exec/fv32pll.x}
CARBONTOTAL=${CARBONTOTAL:-${HOMEgfs}/exec/calc_col_integrals.x}
NCORES=40

#Load modules
source ${HOMEjedi}/jedi_module_base.hera.sh
module load nco
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/libs/fortran-datetime/lib"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1

# Determine sensor ID

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

[[ ! -d ${DATA} ]] && mkdir -p ${DATA}
cd ${DATA}

# Link executables to working director
echo ${FV2LATLONEXEC}
rm -rf ./fv32pll.x ./calc_col_integrals.x
${NCP} ${FV2LATLONEXEC} ./fv32pll.x
#${NCP} ${CARBONTOTAL} ./calc_col_integrals.x

for EXPNAME in ${EXPNAMES}; do
    if [ ${EXPNAME} = ${FREERUNEXP} ]; then
	FIELDS="cntlBkg"
    else
	FIELDS="cntlBkg ensmBkg cntlAnl ensmAnl"
    fi

    CDATE=${SDATE}
    while [ ${CDATE} -le ${EDATE} ]; do
        CYMD=${CDATE:0:8}
        CY=${CDATE:0:4}
        CM=${CDATE:4:2}
        CD=${CDATE:6:2}
        CH=${CDATE:8:2}
        CDATEPRE="${CYMD}.${CH}0000"

        GDATE=$(${NDATE} -${CYCINC} ${CDATE})
	GYMD=${GDATE:0:8}
	GH=${GDATE:8:2}

        for FIELD in ${FIELDS}; do
            if [ ${FIELD} = "ensmBkg" -o ${FIELD} = "ensmAnl" ]; then
                enkfopt="enkf"
		ensmopt="ensmean"
	    else
                enkfopt=""
                ensmopt=""
	    fi

            if [ ${FIELD} = "cntlBkg" -o ${FIELD} = "ensmBkg" ]; then
                TRCR="fv_tracer"
	    else
                TRCR="fv_tracer_aeroanl"
	    fi

            INDIR=${TOPRUNDIR}/${EXPNAME}/dr-data-backup/${enkfopt}gdas.${GYMD}/${GH}/atmos/${ensmopt}/RESTART/
            OUTDIR=${OUTAEROSDIR}/${EXPNAME}/${FIELD}/${CY}/${CY}${CM}/${CY}${CM}${CD}
            [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
	    INTRCR=${CDATEPRE}.${TRCR}.res.tile?.nc
	    INCORE=${CDATEPRE}.fv_core.res.tile?.nc
	    INAKBK=${CDATEPRE}.fv_core.res.nc
	    OUTAEROS=fv3_aeros_${CDATE}_pll.nc
	    OUTAEROS_TMP=fv3_aeros_${CDATE}_pll_tmp.nc
	    OUTAEROS_INIT=fv3_aeros_int_${CDATE}_pll.nc

[[ -f ${OUTDIR}/${OUTAEROS_TMP} ]] && rm -rf ${OUTDIR}/${OUTAEROS_TMP}
[[ -f ${OUTDIR}/${OUTAEROS} ]] && rm -rf ${OUTDIR}/${OUTAEROS}

[[ -f fv32pll.nl ]] && rm -rf fv32pll.nl
cat > fv32pll.nl <<EOF
&record_input
 date="${CDATE}"
 input_grid_dir="${FIXDIR_SELF}/grid_spec/${CASE}"
 fname_grid="${CASE}_grid_spec.tile?.nc"
 input_fv3_dir="${INDIR}"
 fname_fv3_tracer="${INTRCR}"
 fname_fv3_core="${INCORE}"
 fname_akbk="${INAKBK}"
/
&record_interp
!varlist_in is only for illustration since translation is hard-coded
!and will not aggregate correctly if all species not present
 varlist_in= "bc1","bc2","dust1","dust2","dust3","dust4","dust5","oc1","oc\
2","seas1","seas2","seas3","seas4","seas5","so4","no3an1","no3an2","no3an3"
!varlist_out is only for illustration since translation is hard-coded
!and will not aggregate correctly if all species not present
 varlist_out= "BCPHOBIC","BCPHILIC","DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL","OCPHOBIC","OCPHILIC","SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL","SO4", "NITRATE1", "NITRATE2", "NITRATE3"
 plist = 100.,250.,400.,500.,600.,700.,850.,925.,1000.
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${OUTDIR}"
 fname_pll="${OUTAEROS_TMP}"
/
EOF

#srun --export=all -n ${NCORES}  ./fv3aod2ll.x
./fv32pll.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "fv32pll.x failed and exit!!!"
    exit 1
else
    cp fv32pll.nl ${OUTDIR}/fv32pll.nl_${FIELD}_${TRCR}
fi

ncap2 -O -s "CPHOBIC=float(BCPHOBIC+OCPHOBIC);CPHILIC=float(BCPHILIC+OCPHILIC);CTOTAL=float(BCPHOBIC+OCPHOBIC+BCPHILIC+OCPHILIC)" ${OUTDIR}/${OUTAEROS_TMP} ${OUTDIR}/${OUTAEROS}
ncatted -O -a long_name,CPHOBIC,o,c,"Hydrophobic Carbon Aerosol Total Mixing Ratio" ${OUTDIR}/${OUTAEROS}
ncatted -O -a long_name,CPHILIC,o,c,"Hydrophilic Carbon Aerosol Total Mixing Ratio" ${OUTDIR}/${OUTAEROS}
ncatted -O -a long_name,CTOTAL,o,c,"Carbon Aerosol Total Mixing Ratio" ${OUTDIR}/${OUTAEROS}
ncatted -O -a history,global,d,, ${OUTDIR}/${OUTAEROS}

ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "ncat failed and exit!!!"
    exit 1
else
    rm -rf ${OUTDIR}/${OUTAEROS_TMP}
fi

# Calculate column integral on regular lat-lon grid
#cat > calc_col_integrals.nl <<EOF
#&record_input
# input_dir="${OUTDIR}"
# fname_in="${OUTFILE}"
# varlist= "BCPHOBIC","BCPHILIC","DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL","OCPHOBIC","OCPHILIC","SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL","SO4","NITRATE1","NITRATE2","NITRATE3"
#/
#&record_output
# output_dir="${OUTDIR}"
# fname_out="tmp.nc"
#/
#EOF
#
#    ./calc_col_integrals.x
#    ERR=$?
#
#    if [ ${ERR} -ne 0 ]; then
#        echo "calc_col_integrals failed and exit."
#        exit 1
#    else
#        ncap2 -O -s "CPHOBIC_INTEGRAL=float(BCPHOBIC_INTEGRAL+OCPHOBIC_INTEGRAL);CPHILIC_INTEGRAL=float(BCPHILIC_INTEGRAL+OCPHILIC_INTEGRAL);CTOTAL_INTEGRAL=float(BCPHOBIC_INTEGRAL+OCPHOBIC_INTEGRAL+BCPHILIC_INTEGRAL+OCPHILIC_INTEGRAL)" ${OUTDIR}/tmp.nc ${OUTDIR}/${OUTFILE_INT}
#
#        if [ ${ERR} -eq 0 ]; then
#            echo "calc_col_integrals failed and exit."
#            exit 1
#	    cp calc_col_integrals.nl ${OUTDIR}/calc_col_integrals.nl_${FIELD}_${TRCR}
#            rm -rf ${OUTDIR}/tmp.nc
#        fi
#    fi

done # end of Fields

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

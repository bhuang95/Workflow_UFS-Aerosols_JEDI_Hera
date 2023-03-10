#!/bin/bash 


##SBATCH --account=chem-var
##SBATCH --qos=debug
##SBATCH --ntasks=40
##SBATCH --cpus-per-task=10
##SBATCH --time=5
##SBATCH --job-name="bashtest"
##SBATCH --exclusive
##! /usr/bin/env bash

###############################################################
## Abstract:
## Create biomass burning emissions for FV3-CHEM
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################
# Source FV3GFS workflow modules
#. $HOMEgfs/ush/load_fv3gfs_modules.sh
#. /apps/lmod/lmod/init/bash
#module purge
#module load intel impi netcdf/4.6.1 nco # Modules required on NOAA Hera
#set -x
export HOMEjedi=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
. ${HOMEjedi}/jedi_module_base.hera
module list
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"
status=$?
[[ $status -ne 0 ]] && exit $status

export LD_LIBRARY_PATH="/home/Mariusz.Pagowski/MAPP_2018/libs/fortran-datetime/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="/scratch2/BMC/wrfruc/Samuel.Trahan/viirs-thinning/mpiserial/exec:$PATH"
# Make sure we have the required executables
for exe in mpiserial ncrcat ; do
    if ( ! which "$exe" ) ; then
         echo "Error: $exe is not in \$PATH. Go find it and rerun." 1>&2
         #if [[ $ignore_errors == NO ]] ; then exit 1 ; fi
    fi
done
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK # Must match --cpus-per-task in job card
export OMP_STACKSIZE=128M # Should be enough; increase it if you hit the stack limit.

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP/prepaodobs"

[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/"}
OBSDIR_NESDIS=${OBSDIR_NESDIS:-"/scratch2/BMC/public/data/sat/nesdis/viirs/aod/conus/"}
OBSDIR_NRT=${OBSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/aodObs"}
AODTYPE=${AODTYPE:-"VIIRS"}
AODSAT=${AODSAT:-"npp j01"}
CDATE=${CDATE:-"2021060900"}
CYCINTHR=${CYCINTHR:-"6"}
CASE=${CASE:-"C192"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
MISSNPP=${MISSNPP:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/record.missViirsNpp"}
MISSJ01=${MISSJ01:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean/dr-work/record.missViirsJ01"}

#VIIRS2IODAEXEC=/scratch2/BMC/wrfruc/Samuel.Trahan/viirs-thinning/mmapp_2018_src_omp/exec/viirs2ioda.x
VIIRS2IODAEXEC=${HOMEgfs}/exec/viirs2ioda.x
IODAUPGRADEREXEC=${HOMEjedi}/bin/ioda-upgrade.x
#FV3GRID=${HOMEgfs}/fix/fix_fv3/${CASE}
FV3GRID=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_fv3/${CASE}
AODOUTDIR=${OBSDIR_NRT}/${AODTYPE}-${CASE}/${CDATE}/
[[ ! -d ${AODOUTDIR} ]] && mkdir -p ${AODOUTDIR}

RES=`echo $CASE | cut -c2-4`
YY=`echo "${CDATE}" | cut -c1-4`
MM=`echo "${CDATE}" | cut -c5-6`
DD=`echo "${CDATE}" | cut -c7-8`
HH=`echo "${CDATE}" | cut -c9-10`

HALFCYCLE=$(( CYCINTHR/2 ))
STARTOBS=$(${NDATE} -${HALFCYCLE} ${CDATE})
ENDOBS=$(${NDATE} ${HALFCYCLE} ${CDATE})

STARTYY=`echo "${STARTOBS}" | cut -c1-4`
STARTMM=`echo "${STARTOBS}" | cut -c5-6`
STARTDD=`echo "${STARTOBS}" | cut -c7-8`
STARTHH=`echo "${STARTOBS}" | cut -c9-10`
STARTYMD=${STARTYY}${STARTMM}${STARTDD}
STARTYMDHMS=${STARTYY}${STARTMM}${STARTDD}${STARTHH}0000

ENDYY=`echo "${ENDOBS}" | cut -c1-4`
ENDMM=`echo "${ENDOBS}" | cut -c5-6`
ENDDD=`echo "${ENDOBS}" | cut -c7-8`
ENDHH=`echo "${ENDOBS}" | cut -c9-10`
ENDYMD=${ENDYY}${ENDMM}${ENDDD}
ENDYMDHMS=${ENDYY}${ENDMM}${ENDDD}${ENDHH}0000

for sat in ${AODSAT}; do
    FINALFILEv1_tmp="${AODTYPE}_AOD_${sat}.${CDATE}.iodav1.tmp.nc"
    FINALFILEv1="${AODTYPE}_AOD_${sat}.${CDATE}.iodav1.nc"
    FINALFILEv2="${AODTYPE}_AOD_${sat}.${CDATE}.nc"
    [[ -f ${FINALFILEv1_tmp} ]] && /bin/rm -rf ${FINALFILEv1_tmp}
    [[ -f ${FINALFILEv1} ]] && /bin/rm -rf ${FINALFILEv1}
    [[ -f ${FINALFILEv2} ]] && /bin/rm -rf ${FINALFILEv2}
    declare -a usefiles # usefiles is now an array
    usefiles=() # clear the list of files
    allfiles=`ls -1 ${OBSDIR_NESDIS}/*_${sat}_s${STARTYMD}*_*.nc ${OBSDIR_NESDIS}/*_${sat}_*_e${ENDYMD}*_*.nc | sort -u`
    for f in ${allfiles}; do
        # Match the _s(number) start time and make sure it is after the time of interest
	if ! [[ $f =~ ^.*_s([0-9]{14}) ]] || ! (( BASH_REMATCH[1] >= STARTYMDHMS )) ; then
            echo "Skip; too early: $f"
        # Match the _e(number) end time and make sure it is after the time of interest
        elif ! [[ $f =~ ^.*_e([0-9]{14}) ]] || ! (( BASH_REMATCH[1] <= ENDYMDHMS )) ; then
            echo "Skip; too late:  $f"
        else
            echo "Using this file: $f"
            usefiles+=("$f") # Append the file to the usefiles array
        fi
    done
    echo "${usefiles[*]}" | tr ' ' '\n'
    
    # Make sure we found some files.
    echo "Found ${#usefiles[@]} files between $STARTOBS and $ENDOBS."
    if ! (( ${#usefiles[@]} > 0 )) ; then
        echo "Error: no files found for specified time range in ${OBSDIR_NESDIS}" 1>&2
    exit 1
    fi
    
    # Prepare the list of commands to run.
    [[ -f cmdfile ]] && /bin/rm -rf cmdfile
    cat /dev/null > cmdfile
    file_count=0
    for f in "${usefiles[@]}" ; do
        fout=$( basename "$f" )
        echo "${VIIRS2IODAEXEC}" "${CDATE}" "$FV3GRID" "$f" "$fout" >> cmdfile
        file_count=$(( file_count + 1 ))
    done
    
    # Run many tasks in parallel via mpiserial.
    mpiserial_flags='-m '
    echo "Now running executable ${VIIRS2IODAEXEC}"
    if ( ! srun  -l mpiserial $mpiserial_flags cmdfile ) ; then
        echo "At least one of the files failed. See prior logs for details." 1>&2
        exit 1
    fi
    
    # Make sure all files were created.
    no_output=0
    success=0
    for f in "${usefiles[@]}" ; do
        fout=$( basename "$f" )
        if [[ -s "$fout" ]] ; then
            success=$(( success + 1 ))
        else
            no_output=$(( no_output + 1 ))
            echo "Missing output file: $fout"
        fi
    done
    
    if [[ "$success" -eq 0 ]] ; then
        echo "Error: no files were output in this analysis cycle. Perhaps there are no obs at this time?" 1>&2
            exit 1
    fi
    if [[ "$success" -ne "${#usefiles[@]}" ]] ; then
        echo "In analysis cycle ${CDATE}, only $success of ${#usefiles[@]} files were output."
        echo "Usually this means some files had no valid obs. See prior messages for details."
    else
        echo "In analysis cycle ${CDATE}, all $success of ${#usefiles[@]} files were output."
    fi
    
    # Merge the files.
    echo Merging files now...
    if ( ! ncrcat -O JRR-AOD_v2r3_${sat}_*.nc "${FINALFILEv1_tmp}" ) ; then
        echo "Error: ncrcat returned non-zero exit status" 1>&2
        exit 1
    fi
    
    # Make sure they really were merged.
    if [[ ! -s "$FINALFILEv1_tmp" ]] ; then
        echo "Error: ncrcat did not create $FINALFILEv1_tmp ." 1>&2
        exit 1
    fi
     
    ncks --fix_rec_dmn all ${FINALFILEv1_tmp} ${FINALFILEv1}

    echo "IODA_UPGRADE for ${FINALFILEv1}"
    ${IODAUPGRADEREXEC} ${FINALFILEv1} ${FINALFILEv2}
    err=$?
    if [[ $err -eq 0 ]]; then
        /bin/mv ${FINALFILEv1}  ${AODOUTDIR}/
        /bin/mv ${FINALFILEv2}  ${AODOUTDIR}/
	echo ${AODSAT}
	echo ${sat}
	echo ${FINALFILEv2}
	if [ "${AODSAT}" == "npp" ] && [ ${sat} == "npp" ]; then
	    echo "equal to npp"
	    echo ${CDATE} >> ${MISSJ01}
	    /bin/cp ${AODOUTDIR}/${AODTYPE}_AOD_npp.${CDATE}.nc  ${AODOUTDIR}/${AODTYPE}_AOD_j01.${CDATE}.nc
	fi

	if [ "${AODSAT}" == "j01" ] && [ ${sat} == "j01" ]; then
	    echo "equal to j01"
	    echo ${CDATE} >> ${MISSNPP}
	    /bin/cp ${AODOUTDIR}/${AODTYPE}_AOD_j01.${CDATE}.nc  ${AODOUTDIR}/${AODTYPE}_AOD_npp.${CDATE}.nc
	fi
        /bin/rm -rf JRR-AOD_v2r3_${sat}_*.nc
        err=$?
    else
        echo "IODA_UPGRADER failed for ${FINALFILEv1} and exit."
	exit 1
    fi

    #/bin/mv JRR-AOD_v2r3_${sat}_*.nc  ${AODOUTDIR}/
done
    
if [[ $err -eq 0 ]]; then
    /bin/rm -rf $DATA
fi
    
echo $(date) EXITING $0 with return code $err >&2
exit $err

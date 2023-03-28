#!/bin/bash
#SBATCH -n 1
#SBATCH -t 03:30:00
#SBATCH -p service
##SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J AERONET-PLOT
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/plotAeronet.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/plotAeronet.out

export OMP_NUM_THREADS=1
set -x 

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

CURDIR=$(pwd)

SDATE=2017101000
EDATE=2017102718
MISS_AERONET=${CURDIR}/Record_AeronetHfxMissing.info
CINC=6
AODTYPE='AERONET_AOD15'
PMONTH=False
TOPEXPDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/
TOPDIAGDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/AeroDA-1C192-20C192-201710/diagplots/AERONET/${AODTYPE}
SAMPDIR=${TOPDIAGDIR}/SAMPLES
PLOTTMPDIR=${TOPDIAGDIR}/PLOTS-${SDATE}-${EDATE}
DAEXP=AeroDA-1C192-20C192-201710 
NODAEXP=FreeRun-1C192-0C192-201710
DASAMPDIR=${SAMPDIR}/${DAEXP}/
NODASAMPDIR=${SAMPDIR}/${NODAEXP}/
EXPS="${NODAEXP} ${DAEXP}"

[[ ! -d ${PLOTTMPDIR} ]] && mkdir -p ${PLOTTMPDIR}

cd ${PLOTTMPDIR}
cp ${CURDIR}/COLLECT_AERONET_AOD500nm_6H.py ./COLLECT_AERONET_AOD500nm_6H.py
cp ${CURDIR}/COLLECT_AERONET_AOD_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm.py ./COLLECT_AERONET_AOD_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm.py
cp ${CURDIR}/plt_AERONET_AOD_OBS_HFX_MPL_PDF_500nm.py ./plt_AERONET_AOD_OBS_HFX_MPL_PDF_500nm.py
cp ${CURDIR}/plt_AERONET_AOD_COUNT_BIAS_RMSE_MAE_BRRMSE_500nm_relativeError.py ./plt_AERONET_AOD_COUNT_BIAS_RMSE_MAE_BRRMSE_500nm_relativeError.py

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

# Step-1: Output and collect AERONET AOD and HFX samples
echo "Step-1: Output and collect AERONET AOD and HFX samples"
for EXP in ${EXPS}; do
    if [ ${EXP} = ${DAEXP} ]; then
        FIELDS="cntlBkg cntlAnl"
    elif [ ${EXP} = ${NODAEXP} ]; then 
	FIELDS="cntlBkg"
    else
        echo "Please define EXPS and exit now"
	exit 1
    fi
   
    for FIELD in ${FIELDS}; do
        SAMPFILE=${EXP}_${FIELD}_${AODTYPE}_${SDATE}_${EDATE}.out
        CDATE=${SDATE}
        while [ ${CDATE} -le ${EDATE} ]; do
            CY=${CDATE:0:4}
            CM=${CDATE:4:2}
            CD=${CDATE:6:2}
            CH=${CDATE:8:2}
            INDIR=${TOPEXPDIR}/${EXP}/dr-data-backup/gdas.${CY}${CM}${CD}/${CH}/diag/
            OUTDIR=${SAMPDIR}/${EXP}/${FIELD}/${CY}/${CY}${CM}/${CY}${CM}${CD}/
	    [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}

	    OUTFILE=${OUTDIR}/${EXP}_${FIELD}_${AODTYPE}_lon_lat_obs_hfx_${CDATE}.txt
	    if [ -f ${OUTFILE} ];then
                echo "${OUTFILE} exists and continue."
	    else
		if ( grep ${CDATE} ${MISS_AERONET} ); then
		    echo "AERONET missing at ${CDATE} and touch ${OUTFILE}"
                    touch ${OUTFILE}
		else
		    echo "Run COLLECT_AERONET_AOD500nm_6H.py at ${CDATE}"
                    python COLLECT_AERONET_AOD500nm_6H.py -c ${CDATE} -a ${AODTYPE} -f ${FIELD} -i ${INDIR} -o ${OUTFILE}
		    ERR=$?
		    [[ ${ERR} -ne 0 ]] && exit 1
		fi
	    fi

	    if [ ${CDATE} = ${SDATE} ]; then
	        cp ${OUTFILE} ${SAMPFILE}
	    else
	        cat ${OUTFILE} >> ${SAMPFILE}
	    fi
            CDATE=$(${NDATE} ${CINC} ${CDATE})
	done
    done
done
 
# Step-2: Output and collect bias, rmse
echo "Step-2: Output and collect bias, rmse"
cd ${PLOTTMPDIR}
for EXP in ${EXPS}; do
    if [ ${EXP} = ${DAEXP} ]; then
        FIELDS="cntlBkg cntlAnl"
    elif [ ${EXP} = ${NODAEXP} ]; then 
	FIELDS="cntlBkg"
    else
        echo "Please define EXPS and exit now"
	exit 1
    fi
   
    for FIELD in ${FIELDS}; do
        SAMPFILE=${EXP}_${FIELD}_${AODTYPE}_${SDATE}_${EDATE}.out
        OUTFILE=${EXP}_${FIELD}_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}.out
        python COLLECT_AERONET_AOD_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm.py -i ${SAMPFILE} -o ${OUTFILE}
        ERR=$?
        [[ ${ERR} -ne 0 ]] && exit 1
    done
done

# Step-3: Plot scattering density plot
echo "Step-3: Plot scattering density plot"
cd ${PLOTTMPDIR}
CYCLE=${SDATE}-${EDATE}
FREERUN=${NODAEXP}_cntlBkg_${AODTYPE}_${SDATE}_${EDATE}.out
DABKG=${DAEXP}_cntlBkg_${AODTYPE}_${SDATE}_${EDATE}.out
DAANL=${DAEXP}_cntlAnl_${AODTYPE}_${SDATE}_${EDATE}.out

python plt_AERONET_AOD_OBS_HFX_MPL_PDF_500nm.py -c ${CYCLE} -p ${AODTYPE} -m ${PMONTH} -x ${FREERUN} -y ${DABKG} -z ${DAANL}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1

# Step-4: Plot relative bias and rmse
echo "Step-3: Plot relative bias and rmset"
cd ${PLOTTMPDIR}
CYCLE=${SDATE}-${EDATE}
FREERUN=${NODAEXP}_cntlBkg_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}.out
DABKG=${DAEXP}_cntlBkg_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}.out
DAANL=${DAEXP}_cntlAnl_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}.out

python plt_AERONET_AOD_COUNT_BIAS_RMSE_MAE_BRRMSE_500nm_relativeError.py -c ${CYCLE} -p ${AODTYPE} -x ${FREERUN} -y ${DABKG} -z ${DAANL}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1

exit ${ERR}

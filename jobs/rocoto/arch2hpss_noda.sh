#! /usr/bin/env bash

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols//cycExp_ATMA_warm/dr-data"}
EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work"}
RECORDDIR=${RECORDDIR:-"${ROTDIR}/"}
ACCOUNT_HPSS=${ACCOUNT_HPSS:-"wrf-chem"}
CDATE=${CDATE:-"2017110100"}
PSLOT=${PSLOT:-"cycExp_ATMA_warm"}
#CASE_CNTL=${CASE_CNTL:-"C192"}
#CASE_ENKF=${CASE_ENKF:-"C192"}
NMEM_ENKF=${NMEM_ENKF:-"40"}
ARCHHPSSDIR=${ARCHHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/"}
ENSRUN=${ENSRUN:-"TRUE"}

source "${HOMEgfs}/ush/preamble.sh"
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

configs="base"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

HERA2HPSSDIR=${ROTDIR}/HERA2HPSS/${CDATE}
HPSSRECORD=${ROTDIR}/HERA2HPSS/hera2hpss.failed
mkdir -p ${HERA2HPSSDIR}

cat > ${HERA2HPSSDIR}/job_hpss_${CDATE}.sh << EOF
#!/bin/bash --login
#SBATCH -J hpss-${CDATE}
#SBATCH -A ${ACCOUNT_HPSS}
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-${CDATE}.txt
#SBATCH -e ./hpss-${CDATE}.txt

module load hpss
set -x

expName=${PSLOT}
dataDir=${ROTDIR}
caseCntl=${CASE_CNTL}
caseEnkf=${CASE_ENKF}
tmpDir=${HERA2HPSSDIR}
bakupDir=${ROTDIR}/../dr-data-backup
logDir=${ROTDIR}/logs
hpssDir=${ARCHHPSSDIR}
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
NMEM=${NMEM_ENKF}
ENSRUN=${ENSRUN}
HPSSRECORD=${HPSSRECORD}
NMEM_GRP=10
NGRPS=\$((10#\${NMEM} / 10#\${NMEM_GRP}))

nanal=${NMEM_ENKF}
cycN=\`\${incdate} -6 ${CDATE}\`
cycN1=\`\${incdate} 6 \${cycN}\`

mkdir -p \${tmpDir}
mkdir -p \${bakupDir}

echo \${cycN}
cycY=\`echo \${cycN} | cut -c 1-4\`
cycM=\`echo \${cycN} | cut -c 5-6\`
cycD=\`echo \${cycN} | cut -c 7-8\`
cycH=\`echo \${cycN} | cut -c 9-10\`
cycYMD=\`echo \${cycN} | cut -c 1-8\`

echo \${cycN1}
cyc1Y=\`echo \${cycN1} | cut -c 1-4\`
cyc1M=\`echo \${cycN1} | cut -c 5-6\`
cyc1D=\`echo \${cycN1} | cut -c 7-8\`
cyc1H=\`echo \${cycN1} | cut -c 9-10\`
cyc1YMD=\`echo \${cycN1} | cut -c 1-8\`
cyc1prefix=\${cyc1YMD}.\${cyc1H}0000

#hpssDir=/ESRL/BMC/wrf-chem/5year/Bo.Huang/JEDIFV3-AERODA/expRuns/
hpssExpDir=\${hpssDir}/\${expName}/dr-data/\${cycY}/\${cycY}\${cycM}/\${cycY}\${cycM}\${cycD}/
hsi "mkdir -p \${hpssExpDir}"

cntlGDAS=\${dataDir}/gdas.\${cycYMD}/\${cycH}/
cntlGDAS_atmos=\${dataDir}/gdas.\${cycYMD}/\${cycH}/atmos/
cntlGDAS_chem=\${dataDir}/gdas.\${cycYMD}/\${cycH}/chem/

if [ -s \${cntlGDAS} ]; then
### Copy the logfiles
    /bin/cp -r \${logDir}/\${cycN} \${cntlGDAS}/\${cycN}_log
    /bin/rm -rf \${logDir}/\${cycN}/gdasensprepmet0[2-5].log \${cntlGDAS}/\${cycN}_log

### Clean unnecessary cntl files
    /bin/rm -rf \${cntlGDAS_atmos}/gdas.t??z.*?.txt
    /bin/rm -rf \${cntlGDAS_atmos}/gdas.t??z.master.grb2f???
    /bin/rm -rf \${cntlGDAS_atmos}/gdas.t??z.sfluxgrbf???.grib2
   
### Backup cntl data
    cntlBakup_RST=\${bakupDir}/gdas.\${cycYMD}/\${cycH}/atmos/RESTART
    mkdir -p \${cntlBakup_RST}

    /bin/cp -r \${cntlGDAS_atmos}/RESTART/\${cyc1prefix}.coupler* \${cntlBakup_RST}/
    /bin/cp -r \${cntlGDAS_atmos}/RESTART/\${cyc1prefix}.fv_core* \${cntlBakup_RST}/
    /bin/cp -r \${cntlGDAS_atmos}/RESTART/\${cyc1prefix}.fv_tracer* \${cntlBakup_RST}/
    
    ERR=\$?
    if [ \${ERR} -ne 0 ]; then
       echo "Copy Control gdas.\${cycN} failed and exit at error code \${ERR}"
       echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
       exit \${ERR}
    fi

    cd \${cntlGDAS}
    TARFILE=gdas.\${cycN}.tar
    htar -P -cvf \${hpssExpDir}/\${TARFILE}.tar *

    ERR=\$?
    if [ \${ERR} -ne 0 ]; then
       echo "HTAR failed at gdas.\${cycN} and exit at error code \${ERR}"
       echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
       exit \${ERR}
    else
       echo "HTAR at gdas.\${cycN} completed !"
    fi
    
    if [ \${ENSRUN} = "TRUE" ]; then
    ### Start EnKF
        enkfGDAS=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/
        enkfGDAS_atmos=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/atmos
        enkfGDAS_chem=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/chem

    ### Clean unnecessary enkf files
    /bin/rm -rf \${enkfGDAS_atmos}/mem???/*.txt

    ### Backup ensemble mean files
        enkfGDAS_Mean_atmos=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/atmos/ensmean
        enkfBakup_Mean_RST=\${bakupDir}/enkfgdas.\${cycYMD}/\${cycH}/atmos/ensmean/RESTART

        mkdir -p \${enkfBakup_Mean_RST}/
        #/bin/cp -r \${enkfGDAS_Mean}/obs \${enkfBakup_Mean}/
        /bin/cp -r \${enkfGDAS_Mean_atmos}/RESTART/\${cyc1prefix}.coupler* \${enkfBakup_Mean_RST}/
        /bin/cp -r \${enkfGDAS_Mean_atmos}/RESTART/\${cyc1prefix}.fv_tracer* \${enkfBakup_Mean_RST}/
        /bin/cp -r \${enkfGDAS_Mean_atmos}/RESTART/\${cyc1prefix}.fv_core* \${enkfBakup_Mean_RST}/

        ERR=\$?
        if [ \${ERR} -ne 0 ]; then
            echo "Copy ensmean gdas.\${cycN} failed and exit at error code \${ERR}"
            echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
            exit \${ERR}
        fi

#        ianal=1
#        while [ \${ianal} -le \${nanal} ]; do
#           memStr=mem\`printf %03i \$ianal\`
#
#           enkfGDAS_Mem=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/\${memStr}
#           enkfBakup_Mem=\${bakupDir}/enkfgdas.\${cycYMD}/\${cycH}/\${memStr}
#
#           ### clean uncessary mem files
#           /bin/rm -r \${enkfGDAS_Mem}/gdas.t??z.logf???.txt
#
#           ### back mem data
#           mkdir -p \${enkfBakup_Mem}/RESTART
#           /bin/cp -r \${enkfGDAS_Mem}/obs \${enkfBakup_Mem}
#           /bin/cp -r \${enkfGDAS_Mem}/RESTART/*.fv_aod_* \${enkfBakup_Mem}/RESTART/
#           /bin/cp -r \${enkfGDAS_Mem}/RESTART/\${cyc1prefix}.coupler.res.* \${enkfBakup_Mem}/RESTART/
#           /bin/cp -r \${enkfGDAS_Mem}/RESTART/\${cyc1prefix}.fv_tracer.* \${enkfBakup_Mem}/RESTART/
#           /bin/cp -r \${enkfGDAS_Mem}/RESTART/\${cyc1prefix}.fv_core.* \${enkfBakup_Mem}/RESTART/
#
#           ianal=\$[\$ianal+1]
#    
#        done
#
#        if [ \$? != '0' ]; then
#           echo "Copy EnKF enkfgdas.\${cycYMD}\${cycH} failed and exit at error code \$?"
#            echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
#           exit \$?
#        fi
        
        # Tar ensemble files to HPSS
        IGRP=1
        while [ \${IGRP} -le \${NGRPS} ]; do
            ENSED=\$((\${NMEM_GRP} * 10#\${IGRP}))
	    ENSST=\$((ENSED - NMEM_GRP + 1))
	    
	    LGRP_atmos=\${tmpDir}/list.atmos.grp\${IGRP}
	    LGRP_chem=\${tmpDir}/list.chem.grp\${IGRP}
	    [[ -f \${LGRP_atmos} ]] && rm -rf \${LGRP_atmos}
	    [[ -f \${LGRP_chem} ]] && rm -rf \${LGRP_chem}

	    if [ \${IGRP} -ep 1 ]; then
		echo "ensmean" > \${LGRP_atmos}
	    fi

	    IMEM=\${ENSST}
	    while [ \${IMEM} -le \${ENSED} ]; do
		MEMSTR="mem"\`printf %03d \${IMEM}\`
                echo \${MEMSTR} >> \${LGRP_atmos}
                echo \${MEMSTR} >> \${LGRP_chem}
		IMEM=\$((IMEM+1))
	    done
	    IGRP=\$((IGRP+1))
	done

	IGRP=1
	while [ \${IGRP} -le \${NGRPS} ]; do
	    TARFILE=enkfgdas.\${cycN}.atmos.grp\${IGRP}
	    LGRP=\${tmpDir}/list.atmos.grp\${IGRP}
	    cd \${enkfGDAS_atmos}
	    htar -P -cvf \${hpssExpDir}/\${TARFILE}  \$(cat \${LGRP})
	    ERR=\$?
	    echo \${ERR}
	    if [ \${ERR} -ne 0 ]; then
	        echo "HTAR failed at enkfgdas.\${cycN} and grp\${IGRP} and exit at error code \${ERR}"
          	echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
	    	exit \${ERR}
  	    else
  	        echo "HTAR at enkfgdas.\${cycN} completed !"
  	    fi

	    TARFILE=enkfgdas.\${cycN}.chem.grp\${IGRP}
	    LGRP=\${tmpDir}/list.chem.grp\${IGRP}
	    cd \${enkfGDAS_chem}
	    htar -P -cvf \${hpssExpDir}/\${TARFILE}  \$(cat \${LGRP})
	    ERR=\$?
	    echo \${ERR}
	    if [ \${ERR} -ne 0 ]; then
	        echo "HTAR failed at enkfgdas.\${cycN} and grp\${IGRP} and exit at error code \${ERR}"
          	echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
	    	exit \${ERR}
  	    else
  	        echo "HTAR at enkfgdas.\${cycN} completed !"
  	     fi
             IGRP=\$((IGRP+1))
	done
    fi #End of EnKF

    if [ \${ERR} -eq 0 ]; then
        echo "HTAR is successful at \${cycN}"
	#/bin/rm -rf \${enkfGDAS}
	#/bin/rm -rf \${cntlGDAS}
    else
        echo "HTAR failed at \${cycN}"
        echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
        exit \${ERR}
    fi
    #cycN=\`\${incdate} \${cycInc}  \${cycN}\`
fi

exit 0
EOF

#cd ${HERA2HPSSDIR}
#sbatch job_hpss_${CDATE}.sh
ERR=$?

#sleep 60

exit ${ERR}


echo "Archive to HPSS"

exit 0

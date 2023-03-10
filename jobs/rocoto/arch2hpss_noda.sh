#! /usr/bin/env bash

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols//cycExp_ATMA_warm/dr-data"}
CDATE=${CDATE:-"2017110100"}
PSLOT=${PSLOT:-"cycExp_ATMA_warm"}
CASE_CNTL=${CASE_CNTL:-"C192"}
CASE_ENKF=${CASE_ENKF:-"C192"}
NMEM_ENKF=${NMEM_ENKF:-"40"}
ARCHHPSSDIR=${ARCHHPSSDIR:-""}

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

hpssTmp=${ROTDIR}/hpssTmp
mkdir -p ${hpssTmp}

cat > ${hpssTmp}/job_hpss_${CDATE}.sh << EOF
#!/bin/bash --login
#SBATCH -J hpss-${CDATE}
#SBATCH -A ${ACCOUNT_HPSS}
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-${CDATE}-out.txt
#SBATCH -e ./hpss-${CDATE}-err.txt

module load hpss

expName=${PSLOT}
dataDir=${ROTDIR}
caseCntl=${CASE_CNTL}
caseEnkf=${CASE_ENKF}
tmpDir=${ROTDIR}/hpssTmp
bakupDir=${ROTDIR}/../dr-data-backup
logDir=${ROTDIR}/logs
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

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
hpssDir=${ARCHHPSSDIR}
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
    /bin/rm -rf \${cntlGDAS}/gdas.t??z.logf???.txt
    /bin/rm -rf \${cntlGDAS}/gdas.t??z.master.grb2f???
    /bin/rm -rf \${cntlGDAS}/gdas.t??z.sfluxgrbf???.grib2
   
### Backup cntl data
    cntlBakup_RST=\${bakupDir}/gdas.\${cycYMD}/\${cycH}/RESTART
    mkdir -p \${cntlBakup}

    /bin/cp -r \${cntlGDAS_atmos}/RESTART/${cyc1prefix}.coupler* \${cntlBakup_RST}/
    /bin/cp -r \${cntlGDAS_atmos}/RESTART/${cyc1prefix}.fv_core* \${cntlBakup_RST}/
    /bin/cp -r \${cntlGDAS_atmos}/RESTART/${cyc1prefix}.fv_tracer* \${cntlBakup_RST}/

    if [ \$? != '0' ]; then
       echo "Copy Control gdas.\${cycYMD}\${cycH} failed and exit at error code \$?"
       exit \$?
    fi

    #htar -cv -f \${hpssExpDir}/gdas.\${cycN}.tar \${cntlGDAS}
    cd \${cntlGDAS}
    htar -cv -f \${hpssExpDir}/gdas.\${cycN}.tar *
    #hsi ls -l \${hpssExpDir}/gdas.\${cycN}.tar
    stat=\$?
    if [ \${stat} != '0' ]; then
       echo "HTAR failed at gdas.\${cycN}  and exit at error code \${stat}"
	exit \${stat}
    else
       echo "HTAR at gdas.\${cycN} completed !"
       /bin/rm -rf  \${cntlGDAS}   #./gdas.\${cycN}
    fi
    
    if [ \${ENSRUN} = "TRUE" ]; then
    ### Start EnKF
        enkfGDAS_atmos=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/atmos
        enkfGDAS_chem=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/chem

    ### Clean linked data
    #    find \${enkfGDAS}/mem???/RESTART/* -type l -delete

    ### Delite unnecessary ens files
        enkfGDAS_Mean=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/ensmean
        enkfBakup_Mean=\${bakupDir}/enkfgdas.\${cycYMD}/\${cycH}/ensmean

        mkdir -p \${enkfBakup_Mean}/RESTART
        /bin/cp -r \${enkfGDAS_Mean}/obs \${enkfBakup_Mean}/
        /bin/cp -r \${enkfGDAS_Mean}/RESTART/*.fv_aod_* \${enkfBakup_Mean}/RESTART/
        /bin/cp -r \${enkfGDAS_Mean}/RESTART/\${cyc1prefix}.coupler.res.* \${enkfBakup_Mean}/RESTART/
        /bin/cp -r \${enkfGDAS_Mean}/RESTART/\${cyc1prefix}.fv_tracer.* \${enkfBakup_Mean}/RESTART/
        /bin/cp -r \${enkfGDAS_Mean}/RESTART/\${cyc1prefix}.fv_core.* \${enkfBakup_Mean}/RESTART/

        ianal=1
        while [ \${ianal} -le \${nanal} ]; do
           memStr=mem\`printf %03i \$ianal\`

           enkfGDAS_Mem=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/\${memStr}
           enkfBakup_Mem=\${bakupDir}/enkfgdas.\${cycYMD}/\${cycH}/\${memStr}

           ### clean uncessary mem files
           /bin/rm -r \${enkfGDAS_Mem}/gdas.t??z.logf???.txt

           ### back mem data
           mkdir -p \${enkfBakup_Mem}/RESTART
           /bin/cp -r \${enkfGDAS_Mem}/obs \${enkfBakup_Mem}
           /bin/cp -r \${enkfGDAS_Mem}/RESTART/*.fv_aod_* \${enkfBakup_Mem}/RESTART/
           /bin/cp -r \${enkfGDAS_Mem}/RESTART/\${cyc1prefix}.coupler.res.* \${enkfBakup_Mem}/RESTART/
           /bin/cp -r \${enkfGDAS_Mem}/RESTART/\${cyc1prefix}.fv_tracer.* \${enkfBakup_Mem}/RESTART/
           /bin/cp -r \${enkfGDAS_Mem}/RESTART/\${cyc1prefix}.fv_core.* \${enkfBakup_Mem}/RESTART/

           ianal=\$[\$ianal+1]
    
        done

        if [ \$? != '0' ]; then
           echo "Copy EnKF enkfgdas.\${cycYMD}\${cycH} failed and exit at error code \$?"
           exit \$?
        fi

	    #htar -cv -f \${hpssExpDir}/enkfgdas.\${cycN}.tar \${enkfGDAS}
	    cd \${enkfGDAS}
	    htar -cv -f \${hpssExpDir}/enkfgdas.\${cycN}.tar *
	    #hsi ls -l \${hpssExpDir}/enkfgdas.\${cycN}.tar
	    stat=\$?
	    echo \${stat}
	    if [ \${stat} != '0' ]; then
	       echo "HTAR failed at enkfgdas.\${cycN}  and exit at error code \${stat}"
	    	exit \${stat}
  	  else
  	     echo "HTAR at enkfgdas.\${cycN} completed !"
     	  /bin/rm -rf \${enkfGDAS}  #./enkfgdas.\${cycN}
  	  fi
    fi #End of EnKF
    #cycN=\`\${incdate} \${cycInc}  \${cycN}\`
fi
exit 0
EOF

cd ${hpssTmp}
sbatch job_hpss_${CDATE}.sh
err=$?

sleep 60

exit ${err}


echo "Archive to HPSS"

exit 0

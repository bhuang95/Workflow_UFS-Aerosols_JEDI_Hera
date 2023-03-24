#!/bin/bash

TOPDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/CAMSIRA/AOD/
FILEPRE_OLD=camsira_aods_
FILESUF_OLD=_ll.nc
FILEPRE_NEW=camsira_aod_
FILESUF_NEW=_ll.nc

SDATE=2017100600
EDATE=2017103118
INC_H=6

NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

CDATE=$SDATE
while [ $CDATE -le $EDATE ]; do
  CY=${CDATE:0:4}
  CM=${CDATE:4:2}
  CD=${CDATE:6:2}
  CH=${CDATE:8:2}

  FILE_OLD=${TOPDIR}/${CY}/${CY}${CM}/${CY}${CM}${CD}/${FILEPRE_OLD}${CDATE}${FILESUF_OLD}
  FILE_NEW=${TOPDIR}/${CY}/${CY}${CM}/${CY}${CM}${CD}/${FILEPRE_NEW}${CDATE}${FILESUF_NEW}

  if [ ! -f ${FILE_OLD} ]; then
      echo "${FILE_OLD} does not exist and exit now"
      exit 1
  else
      echo ${FILE_OLD}
      echo ${FILE_NEW}
      mv ${FILE_OLD} ${FILE_NEW}
      ERR=$?
      if [ ${ERR} = 0 ]; then
          echo "***************************"
      else
	  exit ${ERR}
      fi
  fi
  CDATE=`$NDATE $INC_H $CDATE`
done
exit ${ERR}

#!/bin/bash
#------------------------------------------------------------------------
# Copyright(C) 2008--2013 Jason Fleming
#
# This file is part of the ADCIRC Surge Guidance System (ASGS).
#
# The ASGS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ASGS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the ASGS.  If not, see <http://www.gnu.org/licenses/>.
#------------------------------------------------------------------------
# Example of invocation:
# ~/asgs/trunk/output/corps_post.sh ~/asgs/config/asgs_config_phil_garnet_hsdrrs2014.sh /lustre/work1/jgflemin/asgs19368/38 99 2008 38 garnet.erdc.hpc.mil nhcConsensus 2008080800  2743200.000000000 HSDRRS2014_MRGO_leveeupdate_fixSTC_MX.grd  ~/asgs/trunk/output /u/jgflemin/asgs/log/asgs-2014-Apr-23-T05:33:41.19368.log ~/.ssh/id_rsa.pub
#
CONFIG=$1
ADVISDIR=$2
STORM=$3
YEAR=$4
ADVISORY=$5
HOSTNAME=$6
ENSTORM=$7
CSDATE=$8
HSTIME=$9
GRIDFILE=${10}
OUTPUTDIR=${11}
SYSLOG=${12}
SSHKEY=${13}
#
STORMDIR=${ADVISDIR}/${ENSTORM}       # shorthand
cd ${STORMDIR}
# get the forecast ensemble member number for use in CERA load balancing
# as well as picking up any bespoke configuration for this ensemble
# member in the configuration files
ENMEMNUM=`grep "forecastEnsembleMemberNumber" ${STORMDIR}/run.properties | sed 's/forecastEnsembleMemberNumber.*://' | sed 's/^\s//'` 2>> ${SYSLOG}
si=$ENMEMNUM
#
# grab all config info
. ${CONFIG} 
# Bring in logging functions
. ${SCRIPTDIR}/monitoring/logging.sh
# Bring in platform-specific configuration
. ${SCRIPTDIR}/platforms.sh
# dispatch environment (using the functions in platforms.sh)
env_dispatch ${TARGET}
# grab all config info (again, last, so the CONFIG file takes precedence)
. ${CONFIG}
#
export PERL5LIB=${PERL5LIB}:${SCRIPTDIR}/PERL
#
#
#-----------------------------------------------------------------------
#          I N C L U S I O N   O F   10 M   W I N D S
#-----------------------------------------------------------------------
# If winds at 10m (i.e., wind velocities that do not include the effect
# of land interaction from nodal attributes line directional wind roughness
# and canopy coefficient) were produced by another ensemble member,
# then include these winds in the post processing
wind10mFound=no
wind10mContoursFinished=no
dirWind10m=$ADVISDIR/${ENSTORM}Wind10m
if [[ -d $dirWind10m ]]; then
   logMessage "Corresponding 10m wind ensemble member was found."
   wind10mFound=yes
   # determine whether the CERA contours are complete for the 10m wind
   # ensemble member
   wind10mContoursHeld=`ls $dirWind10m/cera_contour/*.held 2>> /dev/null | wc -l`
   logMessage "$ENSTORM: $THIS: There are $wind10mContoursHeld .held files for the CERA contours for the 10m winds."
   wind10mContoursStart=`ls $dirWind10m/cera_contour/*.start 2>> /dev/null | wc -l`
   logMessage "$ENSTORM: $THIS: There are $wind10mContoursStart .start files for the CERA contours for the 10m winds."
   wind10mContoursFinish=`ls $dirWind10m/cera_contour/*.finish 2>> /dev/null | wc -l`
   logMessage "$ENSTORM: $THIS: There are $wind10mContoursFinish .finish files for the CERA contours for the 10m winds."
   if [[ $wind10mContoursHeld -eq 0 && $wind10mContoursStart -eq 0 && $wind10mContoursFinish -ne 0 ]]; then
      wind10mContoursFinished=yes
   fi
  for file in fort.72.nc fort.74.nc maxwvel.63.nc ; do
      if [[ -e $dirWind10m/$file ]]; then
         logMessage "$ENSTORM: $THIS: Found $dirWind10m/${file}."
         ln -s $dirWind10m/${file} ./wind10m.${file}
         # update the run.properties file
         case $file in
         "fort.72.nc")
            echo "Wind Velocity 10m Stations File Name : wind10m.fort.72.nc" >> run.properties
            echo "Wind Velocity 10m Stations Format : netcdf" >> run.properties
            ;;
         "fort.74.nc")
            echo "Wind Velocity 10m File Name : wind10m.fort.74.nc" >> run.properties
            echo "Wind Velocity 10m Format : netcdf" >> run.properties
            # if the CERA contours are available, link to them
            if [[ -d $dirWind10m/wvel ]]; then
               ln -s $dirWind10m/wvel ./CERA/wind10m.wvel 2>> $SYSLOG
               # notify downstream processors via run.properties
               if [[ $wind10mContoursFinished = yes ]]; then
                  echo "Wind Velocity 10m Contour Tar File Path : CERA/wind10m.wvel" >> run.properties
                  layersFinished="$layersFinished wind10m.wvel"
               fi
            fi
            ;;
         "maxwvel.63.nc")
            echo "Maximum Wind Speed 10m File Name : wind10m.maxwvel.63.nc" >> run.properties
            echo "Maximum Wind Speed 10m Format : netcdf" >> run.properties
            if [[ -d $dirWind10m/CERA/maxwvelshp ]]; then
               ln -s $dirWind10m/CERA/maxwvelshp ./CERA/wind10m.maxwvelshp 2>> $SYSLOG
               # notify downstream processors via run.properties
               if [[ $wind10mContoursFinished = yes ]]; then
                  echo "Maximum Wind Velocity 10m Contour Tar File Path : CERA/wind10m.maxwvelshp" >> run.properties
                  layersFinished="$layersFinished wind10m.maxwvelshp"
               fi
            fi
            ;;
         *)
            warn "$ENSTORM: $THIS: The file $file was not recognized."
         ;;
         esac
      else
         logMessage "$ENSTORM: $THIS: The file $dirWind10m/${file} was not found."
      fi
   done
else
   logMessage "$ENSTORM: $THIS: Corresponding 10m wind ensemble member was not found."

#-------------------------------------------------------------------
#               C E R A   F I L E   P R I O R I T Y
#-------------------------------------------------------------------
# @jasonfleming: Hack in a notification email once the bare minimum files
# needed by CERA have been posted. 
#
#FILES=(`ls *.nc al${STORM}${YEAR}.fst bal${STORM}${YEAR}.dat fort.15 fort.22 CERA.tar run.properties 2>> /dev/null`)
logMessage "$ENSTORM: $THIS: Creating list of files to post to opendap."
if [[ -e ../al${STORM}${YEAR}.fst ]]; then
   cp ../al${STORM}${YEAR}.fst . 2>> $SYSLOG
fi
if [[ -e ../bal${STORM}${YEAR}.dat ]]; then
   cp ../bal${STORM}${YEAR}.dat . 2>> $SYSLOG
fi
ceraNonPriorityFiles=( `ls endrisinginun.63.nc everdried.63.nc fort.64.nc fort.68.nc fort.71.nc fort.72.nc fort.73.nc initiallydry.63.nc inundationtime.63.nc maxinundepth.63.nc maxrs.63.nc maxvel.63.nc minpr.63.nc rads.64.nc swan_DIR.63.nc swan_DIR_max.63.nc swan_TMM10.63.nc swan_TMM10_max.63.nc` )
ceraPriorityFiles=(`ls run.properties maxele.63.nc fort.63.nc fort.61.nc fort.15 fort.22`)
if [[ $ceraContoursAvailable = yes ]]; then
   ceraPriorityFiles=( ${ceraPriorityFiles[*]} "CERA.tar" )
fi
if [[ $TROPICALCYCLONE = on ]]; then
   ceraPriorityFiles=( ${ceraPriorityFiles[*]} `ls al${STORM}${YEAR}.fst bal${STORM}${YEAR}.dat` )
fi
if [[ $WAVES = on ]]; then
   ceraPriorityFiles=( ${ceraPriorityFiles[*]} `ls swan_HS_max.63.nc swan_TPS_max.63.nc swan_HS.63.nc swan_TPS.63.nc` )
fi
dirWind10m=$ADVISDIR/${ENSTORM}Wind10m
if [[ -d $dirWind10m ]]; then
   ceraPriorityFiles=( ${ceraPriorityFiles[*]} `ls wind10m.maxwvel.63.nc wind10m.fort.74.nc` )
   ceraNonPriorityFiles=( ${ceraNonPriorityFiles[*]} `ls maxwvel.63.nc fort.74.nc` )
else
   ceraPriorityFiles=( ${ceraPriorityFiles[*]} `ls maxwvel.63.nc fort.74.nc` )
fi
FILES=( ${ceraPriorityFiles[*]} "sendNotification" ${ceraNonPriorityFiles[*]} )
#
# write the intended audience to the run.properties file for CERA
echo "intendedAudience : $INTENDEDAUDIENCE" >> run.properties
#
# write the target area to the run.properties file for the CERA
# web app
#echo "asgs : ng" >> run.properties 2>> $SYSLOG
echo "enstorm : $ENSTORM" >> run.properties 2>> $SYSLOG
#-----------------------------------------------------------------------
#         O P E N  D A P    P U B L I C A T I O N 
#-----------------------------------------------------------------------
#
OPENDAPDIR=""
#
# For each opendap server in the list in ASGS config file.
primaryCount=0
for server in ${TDS[*]}; do
   logMessage "$ENSTORM: $THIS: Posting to $server opendap using the following command: ${OUTPUTDIR}/opendap_post.sh $CONFIG $ADVISDIR $ADVISORY $HOSTNAME $ENSTORM $HSTIME $SYSLOG $server \"${FILES[*]}\" $OPENDAPNOTIFY"
   ${OUTPUTDIR}/opendap_post.sh $CONFIG $ADVISDIR $ADVISORY $HOSTNAME $ENSTORM $HSTIME $SYSLOG $server "${FILES[*]}" $OPENDAPNOTIFY >> ${SYSLOG} 2>&1
done

#
# G N U P L O T   F O R   L I N E   G R A P H S
# 
# transpose elevation output file so that we can graph it with gnuplot
STATIONELEVATION=${STORMDIR}/fort.61
if [[ -e $STATIONELEVATION || -e ${STATIONELEVATION}.nc ]]; then
   if [[ -e $STATIONELEVATION.nc ]]; then
      ${OUTPUTDIR}/netcdf2adcirc.x --datafile ${STATIONELEVATION}.nc 2>> ${SYSLOG}
   fi
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose elevation --controlfile ${STORMDIR}/fort.15 --stationfile ${STATIONELEVATION} --format space --coldstartdate $CSDATE --gmtoffset -5 --timezone CDT --units english 2>> ${SYSLOG}
   # now create csv files that can easily be imported into excel
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose elevation --controlfile ${STORMDIR}/fort.15 --stationfile ${STATIONELEVATION} --format comma --coldstartdate $CSDATE --gmtoffset -5 --timezone CDT --units english 2>> ${SYSLOG}
   # rename csv files to something more intuitive
   mv ${STORMDIR}/fort.61_transpose.csv ${STORMDIR}/${STORMNAME}.${ADVISORY}.hydrographs.csv 2>> ${SYSLOG} 2>&1 
fi
# transpose wind velocity output file so that we can graph it with gnuplot
STATIONVELOCITY=${STORMDIR}/fort.72
if [[ -e $STATIONVELOCITY || -e ${STATIONVELOCITY}.nc ]]; then
   if [[ -e $STATIONVELOCITY.nc ]]; then
      ${OUTPUTDIR}/netcdf2adcirc.x --datafile ${STATIONVELOCITY}.nc 2>> ${SYSLOG}
   fi
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose windvelocity --controlfile ${STORMDIR}/fort.15 --stationfile ${STATIONVELOCITY} --format space --vectorOutput magnitude --coldstartdate $CSDATE --gmtoffset -5 --timezone CDT --units english 2>> ${SYSLOG}
   # now create csv files that can easily be imported into excel
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose windvelocity --controlfile ${STORMDIR}/fort.15 --stationfile ${STATIONVELOCITY} --format comma --vectorOutput magnitude --coldstartdate $CSDATE --gmtoffset -5 --timezone CDT --units english 2>> ${SYSLOG}
   # rename csv files to something more intuitive
   mv ${ADVISDIR}/${ENSTORM}/fort.72_transpose.csv ${ADVISDIR}/${ENSTORM}/${STORMNAME}.${ADVISORY}.station.windspeed.csv 2>> ${SYSLOG} 2>&1
fi
# switch to plots directory
if [[ -e ${STORMDIR}/fort.61_transpose.txt || -e ${STORMDIR}/fort.72_transpose.txt ]]; then
   initialDirectory=`pwd`;
   mkdir ${STORMDIR}/plots 2>> ${SYSLOG}
   mv *.txt *.csv ${STORMDIR}/plots 2>> ${SYSLOG}
   cd ${STORMDIR}/plots
   # generate gnuplot scripts for elevation data
   if [[ -e ${STORMDIR}/plots/fort.61_transpose.txt ]]; then
      logMessage "Generating gnuplot script for $ENSTORM hydrographs."
      perl ${OUTPUTDIR}/autoplot.pl --filetoplot ${STORMDIR}/plots/fort.61_transpose.txt --plotType elevation --plotdir ${STORMDIR}/plots --outputdir ${OUTPUTDIR} --timezone CDT --units english --stormname "$STORMNAME" --enstorm $ENSTORM --advisory $ADVISORY --datum NAVD88
   fi
   # plot wind speed data with gnuplot 
   if [[ -e ${STORMDIR}/plots/fort.72_transpose.txt ]]; then
      logMessage "Generating gnuplot script for $ENSTORM wind speed stations."
      perl ${OUTPUTDIR}/autoplot.pl --filetoplot ${STORMDIR}/plots/fort.72_transpose.txt --plotType windvelocity --plotdir ${STORMDIR}/plots --outputdir ${OUTPUTDIR} --timezone CDT --units english --stormname "$STORMNAME" --enstorm $ENSTORM --advisory $ADVISORY --datum NAVD88
   fi
   # execute gnuplot scripts to actually generate the plots
   for plotfile in `ls *.gp`; do
      gnuplot $plotfile 2>> ${SYSLOG}
   done
   # convert them all to png
   for plotfile in `ls *.ps`; do
      pngname=${plotfile%.ps}.png
      convert -rotate 90 $plotfile $pngname 2>> ${SYSLOG}
   done
   plotarchive=${ADVISORY}.plots.tar.gz
   if [[ $TROPICALCYCLONE = on ]]; then
      plotarchive=${YEAR}${STORM}.${plotarchive}
   fi
   # tar up the plots and the csv files
   # also include the maxele.63 file and the original fort.61 and fort.72
   # as requested by Max Agnew and David Ramirez at the New Orleans District
   tar cvzf ${STORMDIR}/${plotarchive} *.png *.csv ../maxele.63 ../fort.61 ../fort.72
   cd $initialDirectory 2>> ${SYSLOG}
fi

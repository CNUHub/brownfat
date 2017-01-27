#!/bin/bash

# build templates for individual scans
# requires CT to already be registered and converted to PET space - via ct_pet_reg.sh
# requires brain mbb and face points file to already exist - maybe created interactively with iiV and scripts recordextents.cnu & selectstudyviews.cnu
# edit filelist to reflect scans for processing
# edit directory and subdirectory paths for environment


date

# list contains triplet for each subject(subject directory name/PET base file name/CT base file name)
filelist="\
E00101/E00101s102/E00101s2 \
E00102/E00102s102/E00102s2 \
E00301/E00301s102/E00301s2 \
E00302/E00302s102/E00302s2 \
E00601/E00601s102/E00601s2 \
E00602/E00602s102/E00602s2 \
E00701/E00701s102/E00701s2 \
E00702/E00702s102/E00702s2 \
E00801/E00801s102/E00801s2 \
E00802/E00802s102/E00802s2 \
E00901/E00901s102/E00901s2 \
E00902/E00902s102/E00902s2 \
E01001/E01001s102/E01001s3 \
E01002/E01002s102/E01002s2 \
E01101/E01101s102/E01101s2 \
E01102/E01102s102/E01102s2 \
E01201/E01201s102/E01201s2 \
E01202/E01202s102/E01202s2 \
E01401/E01401s103/E01401s2 \
E01402/E01402s102/E01402s2 \
E02001/E02001s102/E02001s2 \
E02002/E02002s102/E02002s2 \
E02101/E02101s102/E02101s2 \
E02102/E02102s103/E02102s2 \
E02201/E02201s102/E02201s2 \
E02301/E02301s102/E02301s2 \
E02302/E02302s102/E02302s2 \
E02401/E02401s102/E02401s2 \
E02402/E02402s102/E02402s2 \
E02501/E02501s102/E02501s2 \
E02502/E02502s103/E02502s2 \
E02601/E02601s102/E02601s2 \
E02701/E02701s102/E02701s2 \
E02702/E02702s102/E02702s2 \
E02901/E02901s102/E02901s2 \
E02902/E02902s102/E02902s2 \
E03001/E03001s102/E03001s2 \
E03002/E03002s102/E03002s2 \
E03501/E03501s102/E03501s2 \
E03502/E03502s102/E03502s2 \
E03601/E03601s102/E03601s2 \
E03602/E03602s102/E03602s2 \
E03701/E03701s102/E03701s2 \
E03702/E03702s102/E03702s2 \
E03801/E03801s102/E03801s2 \
E03802/E03802s102/E03802s2 \
E03901/E03901s102/E03901s2 \
E03902/E03902s102/E03902s2 \
E04101/E04101s102/E04101s2 \
E04102/E04102s102/E04102s2 \

"


# subpath where(under each subjects directory) the full 3d pet and ct images will be found
originalssubdir=combined_originals

# other subpaths
templatesubdir=templates
templatedsubdir=templated
flirtsubdir=flirt
normedsubdir=normalized

# common directories
commontemplatedir=/data/luria/experiments/brownfat/commontemplates

# special command path
presmoothcmd="/home/kraepelin/psychiatry/scripts/presmooth"

startdir=`pwd`
for compoundfilename in $filelist; do
    cd ${startdir}

# determine study name
    studyandpetfilename=`dirname ${compoundfilename}`
    study=`dirname ${studyandpetfilename}`
# change study directory -- must be a subdirectory of startdir
    cd ${study}
    pwd

# build name variables
    petfilename=`basename ${studyandpetfilename}`
    ctfilename=`basename ${compoundfilename}`
    cttopetviaflirt=${ctfilename}_in_pet_space_viaflirt
    ctfat=${templatesubdir}/${ctfilename}_adipose
    ctfatpetspace=${ctfat}_pet_space
    facepointfile=${templatesubdir}/${ctfilename}_pet_space_noface_points.txt
    nofacetemplate=${templatesubdir}/${ctfilename}_pet_space_noface_tmplt
    petfilenoring=${templatedsubdir}/${petfilename}_noring
    nofacenobrainadiposenoring=${templatesubdir}/${ctfilename}_pet_space_noface_nobrain_adipose_tmplt

    brainmbbfile=${templatesubdir}/${petfilename}.mbb

# create a mouth/face area template
# requires manually created facepointfile
    if [ ! -e ${facepointfile} ] ; then
      echo "need face point text file: ${facepointfile}"
      echo "use iiV to display ct scan in pet space (${cttopetviaflirt}.nii) and script recordextents.cnu"
      echo "file should contain 4 points as follows:"
      echo "x=85 y=174 z=42 value=54.0 type=ear1 name=E00101s2_in_pet_space_viaflirt.nii"
      echo "x=238 y=182 z=41 value=46.0 type=ear2 name=E00101s2_in_pet_space_viaflirt.nii"
      echo "x=160 y=170 z=71 value=77.0 type=throat1 name=E00101s2_in_pet_space_viaflirt.nii"
      echo "x=168 y=85 z=72 value=92.0 type=chin1 name=E00101s2_in_pet_space_viaflirt.nii"
    fi
    if [ ! -e ${nofacetemplate}.img ] && [ -e ${facepointfile} ] ; then
	ear1=(`cat ${facepointfile} | sed 's/=/ /g' | gawk '/ear1/ {print $2,$4, $6;}'`)
	ear2=(`cat ${facepointfile} | sed 's/=/ /g' | gawk '/ear2/ {print $2,$4, $6;}'`)
	throat1=(`cat ${facepointfile} | sed 's/=/ /g' | gawk '/throat1/ {print $2,$4, $6;}'`)
	chin1=(`cat ${facepointfile} | sed 's/=/ /g' | gawk '/chin1/ {print $2,$4, $6;}'`)
# two vectors in the ear to throat plane
	v1=(`echo "${ear2[0]}-${ear1[0]}; ${ear2[1]}-${ear1[1]}; ${ear2[2]}-${ear1[2]};" | bc`)
# ear1-throat1 instead of throat1-ear1 to get normal pointing posterior?
	v2=(`echo "${ear11[0]}-${throat1[0]}; ${ear1[1]}-${throat1[1]}; ${ear1[2]}-${throat1[2]};" | bc`)
# cross product of plane vectors produces normal
#	${v1[0]} ${v1[1]} ${v1[2]}
#	${v2[0]} ${v2[1]} ${v2[2]}
	n1=(`echo "((${v1[1]}*${v2[2]})-(${v1[2]}*${v2[1]}));\
((${v1[2]}*${v2[0]})-(${v1[0]}*${v2[2]}));\
((${v1[0]}*${v2[1]})-(${v1[1]}*${v2[0]}));" | bc`)
# two vectors in the throat to chin plane
# use vector v1 from ear1 to ear2 to keep parallel to ear plane
# normal should point down (inferior)
#	v3=(${v1[*]})
	v4=(`echo "${throat1[0]}-${chin1[0]}; ${throat1[1]}-${chin1[1]}; ${throat1[2]}-${chin1[2]};" | bc`)
	n2=(`echo "((${v1[1]}*${v4[2]})-(${v1[2]}*${v4[1]}));\
((${v1[2]}*${v4[0]})-(${v1[0]}*${v4[2]}));\
((${v1[0]}*${v4[1]})-(${v1[1]}*${v4[0]}));" | bc`)
	earplanetmpimg=${templatesubdir}/tmp_earplane_$$
	chinplanetmpimg=${templatesubdir}/tmp_chinplane_$$
	echo bldshape -if ${originalssubdir}/${petfilename} ${earplanetmpimg} -bg 0 -fg 1 -analyze -uchar -half ${throat1[0]},${throat1[1]},${throat1[2]},${n1[0]},${n1[1]},${n1[2]}
	bldshape -if ${originalssubdir}/${petfilename} ${earplanetmpimg} -bg 0 -fg 1 -analyze -uchar -half ${throat1[0]},${throat1[1]},${throat1[2]},${n1[0]},${n1[1]},${n1[2]}
	echo bldshape -if ${originalssubdir}/${petfilename} ${chinplanetmpimg} -bg 0 -fg 1 -analyze -uchar -half ${throat1[0]},${throat1[1]},${throat1[2]},${n2[0]},${n2[1]},${n2[2]}
	bldshape -if ${originalssubdir}/${petfilename} ${chinplanetmpimg} -bg 0 -fg 1 -analyze -uchar -half ${throat1[0]},${throat1[1]},${throat1[2]},${n2[0]},${n2[1]},${n2[2]}
	echo addimgs ${earplanetmpimg} ${chinplanetmpimg} -o ${nofacetemplate} -uchar
	addimgs ${earplanetmpimg} ${chinplanetmpimg} -o ${nofacetemplate} -uchar
	rm -f ${earplanetmpimg}.* ${chinplanetmpimg}.*
    fi

# remove ring reconstruction artifact from pet scans
    petsize=(`psyimgheader ${originalssubdir}/${petfilename} |strings| grep "^size=" | sed 's/^size=(//' | sed 's/)//' | sed 's/,/ /g'`)
# commontemplatedir contains templates for different artifact rings depending on the reconstructed pet image size
    petringtemplate=${commontemplatedir}/z${petsize[2]}cylindertemplate.img

    if [ ! -e ${petfilenoring}.img ] ; then
	echo templateimg ${originalssubdir}/${petfilename} ${petfilenoring} -tf ${petringtemplate} -nofill
	templateimg ${originalssubdir}/${petfilename} ${petfilenoring} -tf ${petringtemplate} -nofill
    fi

# build combined template for PET to 1D conversion
    allones_image_sized_source=${commontemplatedir}/allones_x336_y336_z${petsize[2]}
    if [ ! -e ${nofacenobrainadiposenoring}.img ] ; then
      mbb=`cat ${brainmbbfile}`
      zstart=`echo ${mbb} | awk '{print $12+1;}'`
      echo roistats ${allones_image_sized_source} -o ${nofacenobrainadiposenoring} -b 0,0,${brainbottomz},336,336,${petsize[2]} -tf {ctfatpetspace} -tf ${nofacetemplate} -tf ${petringtemplate}
      roistats ${allones_image_sized_source} -o ${nofacenobrainadiposenoring} -b 0,0,${zstart},336,336,${petsize[2]} -tf {ctfatpetspace} -tf ${nofacetemplate} -tf ${petringtemplate}
    fi

done

exit 0

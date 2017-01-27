#!/bin/bash
date
# set up FMRIB Software Library(fsl) for running flirt
FSLDIR=/pkg/wernicke/fsl-4.1.4/fsl/
. ${FSLDIR}/etc/fslconf/fsl.sh
# the following stops flirt from generating gz files defaults to NIFTI_GZ
FSLOUTPUTTYPE=NIFTI
PATH=${PATH}:${FSLDIR}/bin

# list containg triplet for each subject(subject directory name/PET base file name/CT base file name)
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

    cd ${study}
    pwd

    if [ ! -d ${flirtsubdir} ] ; then
      mkdir ${flirtsubdir}
    fi
# convert images to nifti for flirt    
    if [ ! -e ${flirtsubdir}/${ctfilename}.nii ] ; then
	echo scaleimg ${originalssubdir}/${ctfilename} ${flirtsubdir}/${ctfilename} -nifti
	scaleimg ${originalssubdir}/${ctfilename} ${flirtsubdir}/${ctfilename} -nifti
    fi
    if [ ! -e ${flirtsubdir}/${petfilename}.nii ] ; then
	echo scaleimg ${originalssubdir}/${petfilename} ${flirtsubdir}/${petfilename} -nifti
	scaleimg ${originalssubdir}/${petfilename} ${flirtsubdir}/${petfilename} -nifti
    fi
# register and convert ct scan to pet space
    if [ ! -e ${flirtsubdir}/${cttopetviaflirt}.nii.gz ] && [ ! -e ${flirtsubdir}/${cttopetviaflirt}.nii ]  ; then
	cd ${flirtsubdir}
	echo flirt -v -ref ${petfilename}.nii -in ${ctfilename}.nii -out ${cttopetviaflirt}.nii -cost mutualinfo -searchcost mutualinfo -nosearch -out ${cttopetviaflirt}.nii -omat ${cttopetviaflirt}.mat | tee ${cttopetviaflirt}.log
	flirt -v -ref ${petfilename}.nii -in ${ctfilename}.nii -out ${cttopetviaflirt}.nii -cost mutualinfo -searchcost mutualinfo -nosearch -out ${cttopetviaflirt}.nii -omat ${cttopetviaflirt}.mat 2>&1 | tee -a ${cttopetviaflirt}.log
	cd ..
    fi
# unzip flirt output
    if [ ! -e ${flirtsubdir}/${cttopetviaflirt}.nii ] && [ -e ${flirtsubdir}/${cttopetviaflirt}.nii.gz ]; then
	echo gunzip ${flirtsubdir}/${cttopetviaflirt}.nii.gz;
	gunzip ${flirtsubdir}/${cttopetviaflirt}.nii.gz;
    fi

# create templates directory
    if [ ! -d ${templatedsubdir} ] ; then
      mkdir ${templatedsubdir}
    fi

    if [ ! -d ${templatesubdir} ] ; then
      mkdir ${templatesubdir}
    fi

# create adipose template based on range of values from ct scan
    if [ ! -e ${ctfat}.img ] ; then
# output in analyze format for readability by flirt
	echo scaleimg  ${originalssubdir}/${ctfilename} ${ctfat} -ge 887 -minv 0 -le 999 -maxv 0 -analyze
	scaleimg  ${originalssubdir}/${ctfilename} ${ctfat} -ge 887 -minv 0 -le 999 -maxv 0 -analyze
    fi
# transform adipose template to pet space
    if [ ! -e ${ctfatpetspace}.nii ] ; then
	echo flirt -in ${ctfat} -ref flirt/${petfilename}.nii -applyxfm -init flirt/${cttopetviaflirt}.mat -out ${ctfatpetspace}
	flirt -in ${ctfat} -ref flirt/${petfilename}.nii -applyxfm -init flirt/${cttopetviaflirt}.mat -out ${ctfatpetspace}
	echo flirt -in ${ctfat} -ref flirt/${petfilename}.nii -applyxfm -init flirt/${cttopetviaflirt}.mat -out ${ctfatpetspace} > ${ctfatpetspace}.log
    fi

done

exit 0

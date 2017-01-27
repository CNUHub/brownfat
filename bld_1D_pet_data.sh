#!/bin/bash
date
# uncorrected E02102/E02102s102.img - E02102/E02102s103.img corrected but still 2x2mm in plane res
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

# mean to set average brain PET value to
normbrainmean=20000
# extension reflecting normalization mean to add to normalized PET images
normbrainmeanext=nrm20k

# PET threshold option
normedthreshopt="-t 1500 -nofill"
normedthreshext=t1p5knf

# smoothing option
fftopt="-gs 1.5,59"
fftext="gs1p5"

# ct threshold option
ctthreshopt="-tp 30"
ctext=tp30nf

# subpath where(under each subjects directory) the full 3d pet and ct images will be found
originalssubdir=combined_originals

# other subpaths
templatesubdir=templates
templatedsubdir=templated
flirtsubdir=flirt
normedsubdir=normalized

# common directories
commontemplatedir=/data/luria/experiments/brownfat/commontemplates

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
    smoothedfile=${petfilenoring}_${fftext}
    normedimage=${normedsubdir}/${petfilename}_${fftext}_${normbrainmeanext}
    normedimagetemplate=${normedimage}_tmplt
    brainmbbfile=${templatesubdir}/${petfilename}.mbb
    normednofaceadipose=${normedimage}_noface_adipose

    petsize=(`psyimgheader ${originalssubdir}/${petfilename} |strings| grep "^size=" | sed 's/^size=(//' | sed 's/)//' | sed 's/,/ /g'`)
    petringtemplate=${commontemplatedir}/z${petsize[2]}cylindertemplate.img
    allonesimage=${commontemplatedir}/allones_x336_y336_z${petsize[2]}

    nofacenobraintemplate=${templatesubdir}/${ctfilename}_pet_space_noface_nobrain_tmplt
    if [ ! -e ${nofacenobraintemplate}.img ] ; then
        brainmbbfile=${templatesubdir}/${petfilename}.mbb
	mbb=`cat ${brainmbbfile}`
	imgends=(`psyimgheader ${nofacetemplate} |strings| grep "^end=" | sed 's/^end=(//' | sed 's/)//' | sed 's/,/ /g'`)
	zstart=`echo ${mbb} | awk '{print $12+1;}'`
	echo roistats ${allonesimage} -o ${nofacenobraintemplate}  -b 0,0,${zstart},${imgends[0]},${imgends[1]},${imgends[2]} -tf ${nofacetemplate}
        roistats ${allonesimage} -o ${nofacenobraintemplate}  -b 0,0,${zstart},${imgends[0]},${imgends[1]},${imgends[2]} -tf ${nofacetemplate}
    fi


# ** create the template needed to convert desired points to 1d
    fullcombinedtemplate=${templatesubdir}/${ctfilename}_pet_space_noface_nobrain_adipose_tmplt

    if [ ! -e ${fullcombinedtemplate}.img ] ; then
	echo roistats ${allonesimage} -o ${fullcombinedtemplate}  -tf ${ctfatpetspace} -tf ${nofacenobraintemplate} -tf ${petringtemplate}
	roistats ${allonesimage} -o ${fullcombinedtemplate} -tf ${ctfatpetspace} -tf ${nofacenobraintemplate} -tf ${petringtemplate}
    fi

#
    onednormednofaceadipose=${normednofaceadipose}_oneD

    if [ ! -e ${onednormednofaceadipose}.spr ] ; then
      if [ -e ${normednofaceadipose}.img ] ; then
	echo convertto1d ${normednofaceadipose} ${onednormednofaceadipose} -tf ${fullcombinedtemplate} -sdt -float
	convertto1d ${normednofaceadipose} ${onednormednofaceadipose} -tf ${fullcombinedtemplate} -sdt -float
      fi
    fi

done

exit 0

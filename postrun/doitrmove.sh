#!/bin/bash 
#IMAGE	eri-053B153E	tmpXLiTvM6W6F/initrd.img-2.6.28-11-generic.manifest.xml	973425585903	available	public		x86_64	ramdisk		


#for i in `euca-describe-images`
euca-describe-images |while read i
do
  img_id=`echo $i | awk '{ print $2}'`
  echo deregistering $img_id
  euca-deregister $img_id
  img_path=`echo $i | awk '{ print $3}'`
  img_bucket=`echo $img_path |cut -d / -f 1`
  img_manifest=`echo $img_path |cut -d / -f 2`
  img_prefix=`echo $img_manifest |sed s/.manifest.xml//`
  echo deleting bundle in $img_bucket prefixed by $img_prefix
  euca-delete-bundle -b $img_bucket -p $img_prefix
done
# sleep here due to replay attack detection
sleep 2
# 2nd deregister is due to bug in eee that shows image as deregistered until 2nd deregister is issued rt#2501
euca-describe-images |while read i
do
  img_id=`echo $i | awk '{ print $2}'`
  echo deregistering $img_id
  euca-deregister $img_id
done
exit 0


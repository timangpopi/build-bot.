#!/bin/bash
# clone repos for PixelExperience 

GITHUB='https://github.com/Nick89786'
BRANCH="lineage-16.0"

git clone -b $BRANCH $GITHUB/android_device_xiaomi_rolex device/xiaomi/rolex
git clone -b $BRANCH $GITHUB/android_vendor_xiaomi vendor/xiaomi/rolex
git clone -b $BRANCH $GITHUB/android_kernel_xiaomi_msm8917 kernel/xiaomi/msm8917

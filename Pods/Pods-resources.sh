#!/bin/sh
set -e

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
        echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync -av ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -av "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1"`.mom\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd"
      ;;
    *.xcassets)
      ;;
    /*)
      echo "$1"
      echo "$1" >> "$RESOURCES_TO_COPY"
      ;;
    *)
      echo "${PODS_ROOT}/$1"
      echo "${PODS_ROOT}/$1" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
install_resource "CSNotificationView/CSNotificationView/CSNotificationView.xcassets/CSNotificationView_checkmarkIcon.imageset/CSNotificationView_checkmarkIcon.png"
install_resource "CSNotificationView/CSNotificationView/CSNotificationView.xcassets/CSNotificationView_checkmarkIcon.imageset/CSNotificationView_checkmarkIcon@2x.png"
install_resource "CSNotificationView/CSNotificationView/CSNotificationView.xcassets/CSNotificationView_exclamationMarkIcon.imageset/CSNotificationView_exclamationMarkIcon.png"
install_resource "CSNotificationView/CSNotificationView/CSNotificationView.xcassets/CSNotificationView_exclamationMarkIcon.imageset/CSNotificationView_exclamationMarkIcon@2x.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerChecked.imageset/CTAssetsPickerChecked.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerChecked.imageset/CTAssetsPickerChecked@2x.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerChecked~iOS6.imageset/CTAssetsPickerChecked~iOS6.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerChecked~iOS6.imageset/CTAssetsPickerChecked~iOS6@2x.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerLocked.imageset/CTAssetsPickerLocked.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerLocked.imageset/CTAssetsPickerLocked@2x.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerVideo.imageset/CTAssetsPickerVideo.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerVideo.imageset/CTAssetsPickerVideo@2x.png"
install_resource "DBCamera/DBCamera/Resources/DBCameraImages.xcassets"
install_resource "DBCamera/DBCamera/Localizations/en.lproj"
install_resource "DBCamera/DBCamera/Localizations/es.lproj"
install_resource "DBCamera/DBCamera/Localizations/it.lproj"
install_resource "DBCamera/DBCamera/Localizations/pt.lproj"
install_resource "DBCamera/DBCamera/Localizations/tr.lproj"
install_resource "DBCamera/DBCamera/Filters/1977.acv"
install_resource "DBCamera/DBCamera/Filters/amaro.acv"
install_resource "DBCamera/DBCamera/Filters/Hudson.acv"
install_resource "DBCamera/DBCamera/Filters/mayfair.acv"
install_resource "DBCamera/DBCamera/Filters/Nashville.acv"
install_resource "DBCamera/DBCamera/Filters/Valencia.acv"
install_resource "GPUImage/framework/Resources/lookup.png"
install_resource "GPUImage/framework/Resources/lookup_amatorka.png"
install_resource "GPUImage/framework/Resources/lookup_miss_etikate.png"
install_resource "GPUImage/framework/Resources/lookup_soft_elegance_1.png"
install_resource "GPUImage/framework/Resources/lookup_soft_elegance_2.png"
install_resource "Harpy/Harpy/Harpy.bundle"
install_resource "IDMPhotoBrowser/Classes/IDMPhotoBrowser.bundle"
install_resource "IDMPhotoBrowser/Classes/IDMPBLocalizations.bundle"
install_resource "SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle"
install_resource "UzysCircularProgressPullToRefresh/UzysCircularProgressPullToRefresh/UzysCircularProgressPullToRefresh/Library/centerIcon@2x.png"
install_resource "iVersion/iVersion/iVersion.bundle"
install_resource "ionicons/ionicons/ionicons.ttf"
install_resource "${BUILT_PRODUCTS_DIR}/Appirater.bundle"

rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]]; then
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ `xcrun --find actool` ] && [ `find . -name '*.xcassets' | wc -l` -ne 0 ]
then
  case "${TARGETED_DEVICE_FAMILY}" in 
    1,2)
      TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
      ;;
    1)
      TARGET_DEVICE_ARGS="--target-device iphone"
      ;;
    2)
      TARGET_DEVICE_ARGS="--target-device ipad"
      ;;
    *)
      TARGET_DEVICE_ARGS="--target-device mac"
      ;;  
  esac 
  find "${PWD}" -name "*.xcassets" -print0 | xargs -0 actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${IPHONEOS_DEPLOYMENT_TARGET}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi

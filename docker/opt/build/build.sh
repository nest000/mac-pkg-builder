#!/usr/bin/env bash

set -euo pipefail

[[ "${DEBUG:-}" == "1" ]] && set -x

# /app/bin should contains the binary of the application
# /app/resources should contains logo-dark.png, logo-light.png and welcome.html
# /app/scripts can optionally contains a post-install.sh shell script which is triggered after installation routine
# INSTALL_PATH is the target application where the APP will be installed through the pkg installer
# the built package will be saved into /app/dist as pkg file

APP_NAME="${1:-}"
APP_VERSION="${2:-}"
INSTALL_PATH="${3:-}"
WORK_DIR="${4:-/app}"

[[ -z "${APP_NAME}" ]] && { echo "please provide app name as arg1"; exit 1; }
[[ -z "${APP_VERSION}" ]] && { echo "please provide app version as arg2"; exit 1; }
[[ -z "${INSTALL_PATH}" ]] && { echo "please provide app install path as arg3"; exit 1; }

INSTALL_DIR="$(dirname "${INSTALL_PATH}")"
INSTALL_BIN="$(basename "${INSTALL_PATH}")"

BUILD_BIN_DIR="${WORK_DIR}/bin"
OUTPUT_DIR="${WORK_DIR}/dist"
RESOURCES_DIR="${WORK_DIR}/resources"
POST_INSTALL_SCRIPT="${WORK_DIR}/scripts/post-install.sh"

rm -rf "${OUTPUT_DIR}/darwin"

mkdir -p "${OUTPUT_DIR}/darwin/flat/Resources/en.lproj"
mkdir -p "${OUTPUT_DIR}/darwin/flat/base.pkg"
mkdir -p "${OUTPUT_DIR}/darwin/root${INSTALL_DIR}"
mkdir -p "${OUTPUT_DIR}/darwin/scripts"

cp -R "${BUILD_BIN_DIR}"/* "${OUTPUT_DIR}/darwin/root${INSTALL_DIR}"
[[ -f "${POST_INSTALL_SCRIPT}" ]] && cp "${POST_INSTALL_SCRIPT}" ${OUTPUT_DIR}/darwin/scripts/
cp "${RESOURCES_DIR}"/* ${OUTPUT_DIR}/darwin/flat/Resources/en.lproj

chmod +x ${OUTPUT_DIR}/darwin/scripts/*

NUM_FILES=$(find ${OUTPUT_DIR}/darwin/root | wc -l)
INSTALL_KB_SIZE=$(du -k -s ${OUTPUT_DIR}/darwin/root | awk '{print $1}')

addScriptsIfAny=""
[[ -f "${POST_INSTALL_SCRIPT}" ]] && \
addScriptsIfAny=<<EOF
<scripts>
  <postinstall file="./$(basename ${POST_INSTALL_SCRIPT})"/>
</scripts>
EOF

cat <<EOF > ${OUTPUT_DIR}/darwin/flat/base.pkg/PackageInfo
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<pkg-info overwrite-permissions="true" relocatable="false" identifier="${APP_NAME}" postinstall-action="none" format-version="2" generator-version="InstallCmds-502 (14B25)" auth="root">
 <payload numberOfFiles="${NUM_FILES}" installKBytes="${INSTALL_KB_SIZE}"/>
 <bundle-version>
 <bundle id="${APP_NAME}" CFBundleIdentifier="${APP_NAME}" path="${INSTALL_DIR}/${INSTALL_BIN}" CFBundleVersion="${APP_VERSION}"/>
 </bundle-version>
 <update-bundle/>
 <atomic-update-bundle/>
 <strict-identifier/>
 <relocate/>
 ${addScriptsIfAny}
</pkg-info>
EOF

cat <<EOF > ${OUTPUT_DIR}/darwin/flat/Distribution
<?xml version="1.0" encoding="utf-8"?>
<installer-script minSpecVersion="1.000000" authoringTool="com.apple.PackageMaker" authoringToolVersion="3.0.3" authoringToolBuild="174">
 <title>${APP_NAME}</title>
 <options customize="never" allow-external-scripts="no"/>
 <welcome file="welcome.html" mime-type="text/html" />
 <background mime-type="image/png" file="logo-light.png" scaling="proportional" alignment="bottomleft"/>
 <background-darkAqua mime-type="image/png" file="logo-dark.png" scaling="proportional" alignment="bottomleft"/>
 <domains enable_anywhere="true"/>
 <choices-outline>
 <line choice="choice1"/>
 </choices-outline>
 <choice id="choice1" title="base">
 <pkg-ref id="${APP_NAME}.base.pkg"/>
 </choice>
 <pkg-ref id="${APP_NAME}.base.pkg" installKBytes="${INSTALL_KB_SIZE}" auth="Root">#base.pkg</pkg-ref>
</installer-script>
EOF

PKG_LOCATION="${OUTPUT_DIR}/${APP_NAME}.pkg"

( cd ${OUTPUT_DIR}/darwin/root && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > ${OUTPUT_DIR}/darwin/flat/base.pkg/Payload
( cd ${OUTPUT_DIR}/darwin/scripts && find . | cpio -o --format odc --owner 0:80 | gzip -c ) > ${OUTPUT_DIR}/darwin/flat/base.pkg/Scripts
mkbom -u 0 -g 80 ${OUTPUT_DIR}/darwin/root ${OUTPUT_DIR}/darwin/flat/base.pkg/Bom
( cd ${OUTPUT_DIR}/darwin/flat/ && xar --compression none -cf "${PKG_LOCATION}" ./* )
rm -rf ${OUTPUT_DIR}/darwin
echo "osx package has been built: ${PKG_LOCATION}"
#
# Be sure to run `pod lib lint ReerRouter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ReerRouter'
  s.version          = '2.3.2'
  s.summary          = 'A router for iOS app.'

  s.description      = <<-DESC
  App URL router for iOS (Swift only).
                       DESC

  s.homepage         = 'https://github.com/reers/ReerRouter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'phoenix' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/reers/ReerRouter.git', :tag => s.version.to_s }

  s.swift_versions = '5.10'
  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/ReerRouter/**/*', 'Sources/RouterLauncher/**/*'
  # Macro plugin sources are SPM-only (need SwiftSyntax); CocoaPods downloads
  # a prebuilt universal binary from GitHub Release (see script_phase below).
  s.exclude_files = 'Sources/ReerRouterMacros'

  s.preserve_paths = [
    'Package.swift',
    'Sources/ReerRouterMacros',
    'MacroPlugin'
  ]

  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_BUILD_DIR}/ReerRouter/MacroPlugin/ReerRouterMacros#ReerRouterMacros'
  }

  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_BUILD_DIR}/ReerRouter/MacroPlugin/ReerRouterMacros#ReerRouterMacros'
  }

  # Download prebuilt universal macro plugin from GitHub Release
  script = <<-SCRIPT
    set -e

    PLUGIN_DIR="${PODS_BUILD_DIR}/ReerRouter/MacroPlugin"
    PLUGIN_NAME="ReerRouterMacros"
    VERSION="#{s.version}"
    DOWNLOAD_URL="https://github.com/reers/ReerRouter/releases/download/${VERSION}/${PLUGIN_NAME}.zip"

    # Check if plugin already exists
    if [ -x "${PLUGIN_DIR}/${PLUGIN_NAME}" ]; then
      echo "Macro plugin already exists, skipping download."
      exit 0
    fi

    mkdir -p "${PLUGIN_DIR}"

    echo "Downloading prebuilt macro plugin from ${DOWNLOAD_URL}..."

    DOWNLOAD_OK=0
    for i in 1 2 3; do
      if curl -L -f --connect-timeout 30 --max-time 180 --retry 2 --retry-delay 2 \
        -o "${PLUGIN_DIR}/${PLUGIN_NAME}.zip" "${DOWNLOAD_URL}"; then
        DOWNLOAD_OK=1
        break
      fi
      echo "Download attempt ${i} failed, retrying..."
      sleep 2
    done

    if [ "${DOWNLOAD_OK}" -eq 1 ]; then
      unzip -o "${PLUGIN_DIR}/${PLUGIN_NAME}.zip" -d "${PLUGIN_DIR}"
      rm -f "${PLUGIN_DIR}/${PLUGIN_NAME}.zip"
      chmod +x "${PLUGIN_DIR}/${PLUGIN_NAME}"
      echo "Successfully downloaded prebuilt macro plugin"
      file "${PLUGIN_DIR}/${PLUGIN_NAME}"
    else
      echo "Warning: Failed to download prebuilt macro plugin, will build from source..."

      # Fallback: build from source
      env -i PATH="$PATH" HOME="$HOME" "$SHELL" -l -c "swift build -c release --package-path \\"${PODS_TARGET_SRCROOT}\\" --build-path \\"${PODS_BUILD_DIR}/ReerRouter\\" --product ReerRouterMacros"
      cp "${PODS_BUILD_DIR}/ReerRouter/release/ReerRouterMacros-tool" "${PLUGIN_DIR}/${PLUGIN_NAME}"
      chmod +x "${PLUGIN_DIR}/${PLUGIN_NAME}"
      echo "Built macro plugin from source"
      file "${PLUGIN_DIR}/${PLUGIN_NAME}"
    fi
  SCRIPT

  s.script_phase = {
    :name => 'Download ReerRouterMacros Plugin',
    :script => script,
    :execution_position => :before_compile
  }

  s.dependency 'SectionReader'
end

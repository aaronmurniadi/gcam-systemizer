#!/system/bin/sh
# Runs at module install time. Magisk and KernelSU both source this file.

APK_DIR="$MODPATH/system/priv-app/GoogleCamera"

ui_print " "
ui_print "*** Google Camera Systemizer ***"
ui_print " "

if [ ! -f "$APK_DIR/base.apk" ]; then
  abort "! base.apk is missing from $APK_DIR"
fi

ui_print "- APKs in module:"
for f in "$APK_DIR"/*.apk; do
  ui_print "    $(basename "$f")"
done

set_perm_recursive "$MODPATH/system" 0 0 0755 0644

# A privileged app needs an allowlist entry for each signature|privileged permission it requests.
# Google Camera requests one: android.permission.BIND_WALLPAPER.
# Some ROMs already declare the package, for example privapp-permissions-google-p-lineage.xml.
# Add the entry only when the ROM does not declare it, to avoid a duplicate declaration.
if grep -qs "com.google.android.GoogleCamera" /system/etc/permissions/*.xml /product/etc/permissions/*.xml /system_ext/etc/permissions/*.xml; then
  ui_print "- ROM already allowlists com.google.android.GoogleCamera"
else
  ui_print "- ROM does not declare the package; adding BIND_WALLPAPER allowlist"
  mkdir -p "$MODPATH/system/etc/permissions"
  cat > "$MODPATH/system/etc/permissions/privapp-permissions-gcam.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<permissions>
    <privapp-permissions package="com.google.android.GoogleCamera">
        <permission name="android.permission.BIND_WALLPAPER" />
    </privapp-permissions>
</permissions>
XML
  set_perm "$MODPATH/system/etc/permissions/privapp-permissions-gcam.xml" 0 0 0644
fi

ui_print "- Reboot to apply."
ui_print "- After the reboot, set Google Camera as the default camera app."
ui_print " "

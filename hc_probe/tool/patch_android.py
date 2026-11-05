"""Adds the Health Connect setup to the Android project made by `flutter create`.

Run from hc_probe/ after `flutter create`. Safe to run more than once.
"""
import pathlib
import re

root = pathlib.Path("android/app")

# 1. Manifest: read permissions, the Health Connect query, and the
#    permission-rationale entry points Health Connect needs.
perms = [
    "READ_EXERCISE", "READ_STEPS", "READ_DISTANCE", "READ_SLEEP",
    "READ_HEART_RATE", "READ_RESTING_HEART_RATE", "READ_OXYGEN_SATURATION",
    "READ_WEIGHT", "READ_ACTIVE_CALORIES_BURNED", "READ_TOTAL_CALORIES_BURNED",
    "READ_FLOORS_CLIMBED", "READ_HEALTH_DATA_HISTORY",
]
manifest = root / "src/main/AndroidManifest.xml"
m = manifest.read_text()
if "READ_EXERCISE" not in m:
    lines = "".join(
        f'    <uses-permission android:name="android.permission.health.{p}"/>\n'
        for p in perms)
    m = re.sub(r"(<manifest[^>]*>\n)", r"\1" + lines, m, count=1)

if "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" not in m:
    # Inside MainActivity
    m = m.replace(
        "</activity>",
        "    <intent-filter>\n"
        '                <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />\n'
        "            </intent-filter>\n"
        "        </activity>\n"
        "        <activity-alias\n"
        '            android:name="ViewPermissionUsageActivity"\n'
        '            android:exported="true"\n'
        '            android:targetActivity=".MainActivity"\n'
        '            android:permission="android.permission.START_VIEW_PERMISSION_USAGE">\n'
        "            <intent-filter>\n"
        '                <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />\n'
        '                <category android:name="android.intent.category.HEALTH_PERMISSIONS" />\n'
        "            </intent-filter>\n"
        "        </activity-alias>",
        1)
    query = ('        <package android:name="com.google.android.apps.healthdata" />\n'
             "        <intent>\n"
             '            <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />\n'
             "        </intent>\n")
    if "<queries>" in m:
        m = m.replace("<queries>\n", "<queries>\n" + query, 1)
    else:
        m = m.replace("</manifest>", "    <queries>\n" + query + "    </queries>\n</manifest>")
m = m.replace('android:label="hc_probe"', 'android:label="HC Probe"')
manifest.write_text(m)

# 2. MainActivity must be a FlutterFragmentActivity for the permission screen.
for kt in root.glob("src/main/kotlin/**/MainActivity.kt"):
    s = kt.read_text()
    s = s.replace("io.flutter.embedding.android.FlutterActivity",
                  "io.flutter.embedding.android.FlutterFragmentActivity")
    s = re.sub(r"\bFlutterActivity\(\)", "FlutterFragmentActivity()", s)
    kt.write_text(s)

# 3. Health Connect needs Android 8 (API 26) or newer.
gradle = root / "build.gradle.kts"
g = gradle.read_text()
g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 26", g)
gradle.write_text(g)

print("Patched manifest, MainActivity and minSdk.")

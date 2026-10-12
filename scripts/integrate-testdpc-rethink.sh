#!/usr/bin/env bash
set -euo pipefail
mkdir -p rethink/testdpc/src/main
cp -a testdpc/src/main/java rethink/testdpc/src/main/
cp -a testdpc/src/main/res rethink/testdpc/src/main/
cp -a testdpc/src/main/aidl rethink/testdpc/src/main/
cp testdpc/src/main/AndroidManifest.xml rethink/testdpc/src/main/AndroidManifest.xml
mkdir -p rethink/setupdesign rethink/setupcompat rethink/setupdesign-strings
curl --retry 6 --retry-all-errors --retry-delay 3 -fL 'https://gitlab.com/aosp-mirror-1/platform/external/setupdesign/-/archive/main/setupdesign-main.tar.gz' | tar -xz --strip-components=1 -C rethink/setupdesign
curl --retry 6 --retry-all-errors --retry-delay 3 -fL 'https://gitlab.com/aosp-mirror-1/platform/external/setupcompat/-/archive/main/setupcompat-main.tar.gz' | tar -xz --strip-components=1 -C rethink/setupcompat
# These source archives contain upstream Groovy build files that shadow our Gradle module scripts.
rm -f rethink/setupcompat/build.gradle rethink/setupdesign/build.gradle
# Normalize source archives into standard Android library source layouts.
mkdir -p rethink/setupcompat/src/main/java rethink/setupcompat/src/main/res rethink/setupcompat/src/main/aidl
[ ! -d rethink/setupcompat/main/java ] || cp -a rethink/setupcompat/main/java/. rethink/setupcompat/src/main/java/
[ ! -d rethink/setupcompat/main/res ] || cp -a rethink/setupcompat/main/res/. rethink/setupcompat/src/main/res/
[ ! -d rethink/setupcompat/main/aidl ] || cp -a rethink/setupcompat/main/aidl/. rethink/setupcompat/src/main/aidl/
[ ! -d rethink/setupcompat/partnerconfig/java ] || cp -a rethink/setupcompat/partnerconfig/java/. rethink/setupcompat/src/main/java/
[ ! -f rethink/setupcompat/AndroidManifest.xml ] || cp rethink/setupcompat/AndroidManifest.xml rethink/setupcompat/src/main/AndroidManifest.xml
mkdir -p rethink/setupdesign/src/main/java rethink/setupdesign/src/main/res rethink/setupdesign-strings/src/main/res
[ ! -d rethink/setupdesign/main/src ] || cp -a rethink/setupdesign/main/src/. rethink/setupdesign/src/main/java/
[ ! -d rethink/setupdesign/main/res ] || cp -a rethink/setupdesign/main/res/. rethink/setupdesign/src/main/res/
[ ! -d rethink/setupdesign/strings/res ] || cp -a rethink/setupdesign/strings/res/. rethink/setupdesign-strings/src/main/res/
[ ! -f rethink/setupdesign/main/AndroidManifest.xml ] || cp rethink/setupdesign/main/AndroidManifest.xml rethink/setupdesign/src/main/AndroidManifest.xml
cat > rethink/testdpc/build.gradle.kts <<'GRADLE'
plugins { id("com.android.library") }
android { namespace = "com.afwsamples.testdpc"; compileSdk = 35; buildFeatures { aidl = true }; defaultConfig { minSdk = 23 } }
dependencies {
 implementation("androidx.appcompat:appcompat:1.7.0")
 implementation("androidx.annotation:annotation:1.9.1")
 implementation("androidx.core:core:1.15.0")
 implementation("androidx.enterprise:enterprise-feedback:1.1.0")
 implementation("androidx.legacy:legacy-support-v13:1.0.0")
 implementation("androidx.lifecycle:lifecycle-common:2.8.7")
 implementation("androidx.lifecycle:lifecycle-process:2.8.7")
 implementation("androidx.lifecycle:lifecycle-runtime:2.8.7")
 implementation("androidx.localbroadcastmanager:localbroadcastmanager:1.1.0")
 implementation("androidx.recyclerview:recyclerview:1.3.2")
 implementation("androidx.preference:preference:1.2.1")
 implementation("androidx.collection:collection:1.4.5")
 implementation("com.google.guava:guava:33.3.1-android")
 implementation("org.bouncycastle:bcpkix-jdk15on:1.70")
 implementation("org.bouncycastle:bcprov-jdk15on:1.70")
 implementation("dev.rikka.shizuku:api:13.1.5")
 implementation("dev.rikka.shizuku:provider:13.1.5")
 implementation("com.google.zxing:core:3.5.3")
 implementation(project(":setupdesign"))
 implementation(project(":setupcompat"))
}
GRADLE
python3 - <<'PY'
from pathlib import Path
p=Path("rethink/settings.gradle.kts"); s=p.read_text()
for module in (":testdpc", ":setupdesign", ":setupcompat", ":setupdesign-strings"):
    if f'include("{module}")' not in s: s += f'\ninclude("{module}")\n'
p.write_text(s)
p=Path("rethink/app/build.gradle.kts"); s=p.read_text()
if 'implementation(project(":testdpc"))' not in s:
 if 'dependencies {' not in s: raise SystemExit("app dependencies block not found")
 p.write_text(s.replace('dependencies {','dependencies {\n    implementation(project(":testdpc"))',1))
p=Path("rethink/testdpc/src/main/java/com/afwsamples/testdpc/PolicyManagementActivity.java"); s=p.read_text()
a='''  public boolean onCreateOptionsMenu(Menu menu) {
    getMenuInflater().inflate(R.menu.policy_management_menu, menu);
    return true;
  }'''
b='''  public boolean onCreateOptionsMenu(Menu menu) {
    getMenuInflater().inflate(R.menu.policy_management_menu, menu);
    menu.add(0, 90001, 100, "Open Rethink").setShowAsAction(MenuItem.SHOW_AS_ACTION_NEVER);
    return true;
  }'''
if a not in s: raise SystemExit("menu anchor mismatch")
s=s.replace(a,b,1)
a='''    int itemId = item.getItemId();
    if (itemId == R.id.action_show_search) {'''
b='''    int itemId = item.getItemId();
    if (itemId == 90001) {
      Intent rethink = new Intent();
      rethink.setClassName(this, "com.celzero.bravedns.ui.HomeScreenActivity");
      startActivity(rethink);
      return true;
    } else if (itemId == R.id.action_show_search) {'''
if a not in s: raise SystemExit("menu handler anchor mismatch")
p.write_text(s.replace(a,b,1))
PY

# Integration is performed only in the CI workspace; upstream repositories remain unchanged.

cat > rethink/setupcompat/build.gradle.kts <<'GRADLE'
plugins { id("com.android.library") }
android {
    namespace = "com.google.android.setupcompat"
    compileSdk = 35
    buildFeatures { aidl = true }
    defaultConfig { minSdk = 23 }
}
dependencies {
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("androidx.window:window:1.3.0")
    implementation("com.google.errorprone:error_prone_annotations:2.36.0")
}
GRADLE
cat > rethink/setupdesign-strings/build.gradle.kts <<'GRADLE'
plugins { id("com.android.library") }
android {
    namespace = "com.google.android.setupdesign.strings"
    compileSdk = 35
    defaultConfig { minSdk = 23 }
}
GRADLE
cat > rethink/setupdesign/build.gradle.kts <<'GRADLE'
plugins { id("com.android.library") }
android {
    namespace = "com.google.android.setupdesign"
    compileSdk = 35
    defaultConfig { minSdk = 23 }
}
dependencies {
    implementation(project(":setupcompat"))
    implementation(project(":setupdesign-strings"))
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.recyclerview:recyclerview:1.3.2")
    implementation("androidx.window:window:1.3.0")
    implementation("androidx.core:core:1.15.0")
    implementation("androidx.customview:customview:1.2.0")
    implementation("androidx.fragment:fragment:1.8.5")
    implementation("androidx.vectordrawable:vectordrawable:1.2.0")
    implementation("com.google.errorprone:error_prone_annotations:2.36.0")
}
GRADLE

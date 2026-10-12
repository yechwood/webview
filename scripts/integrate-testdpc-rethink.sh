#!/usr/bin/env bash
set -euo pipefail
mkdir -p rethink/testdpc/src/main
cp -a testdpc/src/main/java rethink/testdpc/src/main/
cp -a testdpc/src/main/res rethink/testdpc/src/main/
cp -a testdpc/src/main/aidl rethink/testdpc/src/main/
cp testdpc/src/main/AndroidManifest.xml rethink/testdpc/src/main/AndroidManifest.xml
cat > rethink/testdpc/build.gradle.kts <<'GRADLE'
plugins { id("com.android.library") }
android { namespace = "com.afwsamples.testdpc"; compileSdk = 35; defaultConfig { minSdk = 23 } }
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
 implementation("com.google.android.setupdesign:setupdesign:3.1.2")
 implementation("com.google.android.setupcompat:setupcompat:3.0.3")
}
GRADLE
python3 - <<'PY'
from pathlib import Path
p=Path("rethink/settings.gradle.kts"); s=p.read_text()
if 'include(":testdpc")' not in s: p.write_text(s+'\ninclude(":testdpc")\n')
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

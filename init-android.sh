#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PKG="${1:-com.keno.app}"
MOD="${2:-androidApp}"

say(){ printf "\033[1;32m→ %s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m⚠ %s\033[0m\n" "$*"; }

# .gitignore
cat > .gitignore <<'EOF'
/.idea/
/*.iml
/local.properties
**/build/
.gradle/
EOF

# settings.gradle.kts
cat > settings.gradle.kts <<EOF
pluginManagement {
  repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories { google(); mavenCentral() }
}
rootProject.name = "keno"
include(":$MOD")
EOF

# gradle.properties
cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
EOF

# Modul: build.gradle.kts
mkdir -p "$MOD"
cat > "$MOD/build.gradle.kts" <<EOF
plugins {
  id("com.android.application") version "8.5.2"
  id("org.jetbrains.kotlin.android") version "1.9.24"
}
android {
  namespace = "$PKG"
  compileSdk = 34
  defaultConfig {
    applicationId = "$PKG"
    minSdk = 24
    targetSdk = 34
    versionCode = 1
    versionName = "1.0"
  }
  buildTypes {
    release { isMinifyEnabled = false }
  }
}
dependencies {
  implementation("androidx.core:core-ktx:1.13.1")
  implementation("androidx.appcompat:appcompat:1.7.0")
  implementation("com.google.android.material:material:1.12.0")
}
EOF

# Manifest
mkdir -p "$MOD/src/main"
cat > "$MOD/src/main/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="$PKG">
  <application android:label="Keno" android:icon="@mipmap/ic_launcher">
    <activity android:name=".$(echo "$PKG" | sed 's/.*\.//') .MainActivity"
              android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
EOF

# Ikona (stub) i res
mkdir -p "$MOD/src/main/res/mipmap-anydpi-v26" "$MOD/src/main/res/values"
cat > "$MOD/src/main/res/values/strings.xml" <<'EOF'
<resources>
  <string name="app_name">Keno</string>
</resources>
EOF

# MainActivity.kt
PKG_PATH="${PKG//./\/}"
mkdir -p "$MOD/src/main/java/$PKG_PATH"
cat > "$MOD/src/main/java/$PKG_PATH/MainActivity.kt" <<EOF
package $PKG
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val tv = TextView(this)
    tv.text = "Hello from CI build!"
    setContentView(tv)
  }
}
EOF

# GitHub Actions workflow (nema potrebe za tokenom – triger je push)
mkdir -p .github/workflows
cat > .github/workflows/android.yml <<EOF
name: Build Android Debug APK
on:
  push:
    branches: [ "main" ]
    paths:
      - "$MOD/**"
      - "settings.gradle.kts"
      - "gradle.properties"
      - ".github/workflows/android.yml"
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      # Provereno: instalira i pokreće Gradle bez wrappera
      - name: Build with Gradle
        uses: gradle/gradle-build-action@v2
        with:
          gradle-version: '8.8'
          arguments: ":$MOD:assembleDebug --stacktrace"

      - name: Collect logs & reports
        if: always()
        run: |
          mkdir -p artifacts/apk artifacts/logs artifacts/reports
          cp -r $MOD/build/outputs/apk/debug/*.apk artifacts/apk/ 2>/dev/null || true
          cp -r ~/.gradle/daemon artifacts/logs/daemon 2>/dev/null || true
          find . -path "*/build/reports" -type d -exec cp -r {} artifacts/reports \; 2>/dev/null || true

      - name: Upload APK
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: artifacts/apk/*.apk
          if-no-files-found: warn

      - name: Upload Gradle logs and reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: gradle-logs-and-reports
          path: artifacts
          if-no-files-found: warn
EOF

say "Git commit & push…"
git add .
git commit -m "chore: minimal Android app + CI"
git push -u origin main

say "Gotovo. Otvori GitHub → Actions → 'Build Android Debug APK' i isprati run."
say "APK i logove ćeš naći u 'Artifacts' čak i ako build padne."

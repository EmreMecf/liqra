import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase — FAZ 5
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// key.properties dosyasından imzalama bilgilerini oku.
// Dosya yoksa (CI, yeni klon, debug geliştirme) imzalama yapılandırması
// tamamen atlanır — aksi halde configure aşamasında build çöker.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}
val hasReleaseSigning = keyPropertiesFile.exists() &&
    keyProperties["storeFile"] != null &&
    keyProperties["storePassword"] != null &&
    keyProperties["keyAlias"] != null &&
    keyProperties["keyPassword"] != null

android {
    namespace  = "com.emrec.muhasebe"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.emrec.muhasebe"
        minSdk        = 23   // Firebase Messaging için minimum 23
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName

        // Çok dilli destek (Türkçe + İngilizce)
        resConfigs("tr", "en")

        // Multidex — büyük proje için
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile     = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
                keyAlias      = keyProperties["keyAlias"] as String
                keyPassword   = keyProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // applicationIdSuffix KULLANMA — google-services.json yalnızca
            // com.emrec.muhasebe için kayıtlı; sonek eklenirse plugin
            // "No matching client found" hatasıyla build'i keser.
            versionNameSuffix = "-debug"
            isDebuggable      = true
        }
        release {
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // key.properties yoksa debug anahtarıyla imzala (build kesilmesin)
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("[liqra] key.properties bulunamadı — release build debug anahtarıyla imzalanıyor.")
                signingConfigs.getByName("debug")
            }
        }
    }

    // APK bölme — Play Store için boyut optimizasyonu
    bundle {
        language { enableSplit = true }
        density  { enableSplit = true }
        abi      { enableSplit = true }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

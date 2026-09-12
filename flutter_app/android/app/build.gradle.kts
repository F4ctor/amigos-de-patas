plugins {
    id("com.android.application")
    // O plugin do Flutter deve ser aplicado depois do plugin Android.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.alexcosta.ong_adocao_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.alexcosta.ong_adocao_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Para o TCC, a compilação de demonstração usa a assinatura de debug.
            // Antes de publicar na Play Store, crie uma chave de assinatura própria.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

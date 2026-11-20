import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The application id lives in one file so it can be renamed without hunting
// through Gradle. See config/application_id.txt.
val applicationIdFile = rootProject.file("../config/application_id.txt")
val catlogicApplicationId = applicationIdFile.readText().trim()
val generatedAppIdDir = File(rootProject.projectDir.parentFile, "build/generated_app_id")

val generateMainActivity =
    tasks.register("generateMainActivity") {
        inputs.file(applicationIdFile)
        outputs.dir(generatedAppIdDir)
        doLast {
            val id = applicationIdFile.readText().trim()
            val out = generatedAppIdDir.resolve(id.replace('.', '/'))
            out.mkdirs()
            out.resolve("MainActivity.kt").writeText(
                """
                package $id

                import io.flutter.embedding.android.FlutterActivity

                class MainActivity : FlutterActivity()
                """.trimIndent() + "\n",
            )
        }
    }

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = catlogicApplicationId
    // Play requires API 36 for new apps and updates as of 31 August 2026.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets.named("main") {
        java.srcDir(generatedAppIdDir)
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
                val storePath = keystoreProperties.getProperty("storeFile")
                storeFile = if (storePath.startsWith("/")) file(storePath) else rootProject.file(storePath)
            }
        }
    }

    defaultConfig {
        applicationId = catlogicApplicationId
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    // Debug signing keeps release builds runnable before a keystore exists.
                    signingConfigs.getByName("debug")
                }
        }
    }
}

tasks.named("preBuild").configure {
    dependsOn(generateMainActivity)
}

tasks.configureEach {
    if (name.contains("Kotlin") && name.contains("compile")) {
        dependsOn(generateMainActivity)
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

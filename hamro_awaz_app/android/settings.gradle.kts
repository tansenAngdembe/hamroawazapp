import org.gradle.api.tasks.compile.JavaCompile

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")

// Ensure Kotlin compiles before Java in plugins (e.g. shared_preferences_android).
gradle.beforeProject {
    if (it == it.rootProject) return@beforeProject
    it.afterEvaluate { project ->
        project.tasks.withType<JavaCompile>().configureEach {
            val kotlinTasks = project.tasks.matching { task ->
                task.name.startsWith("compile") && task.name.contains("Kotlin", ignoreCase = true)
            }
            if (kotlinTasks.isNotEmpty()) {
                dependsOn(kotlinTasks)
            }
        }
    }
}

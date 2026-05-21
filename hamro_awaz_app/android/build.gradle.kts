import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Only redirect local modules (:app). Pub-cache plugins stay on the same drive as
    // their sources to avoid "different roots" and IDE sync failures on Windows.
    val androidDir = rootProject.projectDir.canonicalFile
    if (project.projectDir.canonicalFile.startsWith(androidDir)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}

// shared_preferences_android: Java references Kotlin (StringListObjectInputStream).
subprojects {
    pluginManager.withPlugin("kotlin-android") {
        afterEvaluate {
            tasks.withType<JavaCompile>().configureEach {
                if (!name.endsWith("JavaWithJavac")) return@configureEach
                val variant = name.removePrefix("compile").removeSuffix("JavaWithJavac")
                dependsOn(tasks.named("compile${variant}Kotlin"))
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

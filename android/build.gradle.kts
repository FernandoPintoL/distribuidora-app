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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Workaround for "Type T not present" error with AGP 8.9.1 + Gradle 8.11.1 + Java 24
    // and for lint model generation issues
    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            if (android is com.android.build.gradle.LibraryExtension) {
                android.testOptions.unitTests.isIncludeAndroidResources = false
                android.testOptions.unitTests.isReturnDefaultValues = true

                // Disable lint completely for library modules
                android.lint.checkReleaseBuilds = false
                android.lint.abortOnError = false
                android.lint.checkDependencies = false
                android.lint.checkGeneratedSources = false
            }
        }

        // Disable ALL lint-related tasks and unit test compilation tasks
        tasks.configureEach {
            if (name.contains("lint", ignoreCase = true) ||
                name.contains("Lint", ignoreCase = false) ||
                name.contains("UnitTest") ||
                name.contains("test", ignoreCase = true) && name.contains("compile", ignoreCase = true)) {
                enabled = false
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

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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround: some plugins (e.g. `printing`) declare compileSdkVersion 30,
// which lacks android:attr/lStar (API 31+). Force a compatible compileSdk
// for every Android library module so resource linking succeeds.
// Workaround: the `printing` plugin pins compileSdkVersion 30, which lacks
// android:attr/lStar (API 31+), breaking resource linking. Bump only that
// module's compileSdk. Other modules keep their own (correct) values.
subprojects {
    if (!project.state.executed) {
        afterEvaluate {
            if (project.plugins.hasPlugin("com.android.library") && project.name == "printing") {
                val androidExt = extensions.findByName("android")
                if (androidExt != null) {
                    try {
                        androidExt.javaClass
                            .getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                            .invoke(androidExt, 34)
                    } catch (_: Exception) {
                        // ignore if the method signature differs across AGP versions
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

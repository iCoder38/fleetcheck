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

// Some plugins (e.g. `printing` 5.13.1) hardcode an old compileSdkVersion in
// their own android/build.gradle. That predates Android 12's
// android:attr/lStar resource, so once anything in the app is compiled
// against a newer SDK, those plugin modules fail resource verification with
// "AAPT: error: resource android:attr/lStar not found." Force every Android
// library subproject to compile against the app's SDK level so resource
// linking is consistent across all modules.
subprojects {
    // afterEvaluate runs once this subproject's own build.gradle has finished
    // executing, so this override applies AFTER (and wins over) a plugin's own
    // hardcoded `compileSdkVersion 30` line — doing this via plugins.withId()
    // instead fires too early, before that line runs, and gets clobbered by it.
    // :app is already evaluated by this point (evaluationDependsOn above), so
    // afterEvaluate can't be registered on it — apply immediately there instead.
    fun overrideCompileSdk() {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
            // Matches flutter.compileSdkVersion (see FlutterExtension.kt in the
            // Flutter SDK) — keep these two in sync if that value ever changes.
            compileSdk = 36
        }
    }
    if (project.state.executed) overrideCompileSdk() else afterEvaluate { overrideCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

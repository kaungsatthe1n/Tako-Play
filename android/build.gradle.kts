allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val sharedBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(sharedBuildDir)

subprojects {
    project.layout.buildDirectory.value(sharedBuildDir.dir(project.name))
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

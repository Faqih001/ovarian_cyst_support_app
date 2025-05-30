buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Add configuration to resolve dependency conflicts
    configurations.all {
        resolutionStrategy {
            // Force specific versions for conflicting dependencies
            force("com.google.firebase:firebase-iid:21.1.0")
            force("com.google.firebase:firebase-messaging:23.4.1")
            
            // Exclude conflicting classes
            exclude(group = "com.google.firebase", module = "firebase-iid")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

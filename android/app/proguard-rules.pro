############################################
# FLUTTER
############################################
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

############################################
# FIREBASE
############################################
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

############################################
# SENTRY
############################################
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

############################################
# OKHTTP / OKIO
############################################
-dontwarn okhttp3.**
-dontwarn okio.**

############################################
# HYPERVERGE
############################################
-keep class co.hyperverge.** { *; }

############################################
# MODEL CLASSES
############################################
-keep class com.UnoSales.unosfa.models.** {
    *;
}

############################################
# JSON SERIALIZATION (GSON/JACKSON)
############################################
-keepattributes Signature
-keepattributes *Annotation*

############################################
# REMOVE LOGS IN RELEASE
############################################
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

############################################
# OPTIONAL SECURITY HARDENING
############################################
-allowaccessmodification
-optimizations !code/simplification/arithmetic

############################################
# REMOVE SOURCE CODE METADATA
############################################
-renamesourcefileattribute SourceFile

############################################
# GOOGLE PLAY CORE (Flutter deferred components)
############################################
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

############################################
# ANTI-REVERSE ENGINEERING
############################################
# Remove all debug metadata
-keepattributes !LocalVariableTable,!LocalVariableTypeTable
# Strip source file info (you already have this)
-renamesourcefileattribute SourceFile
# Aggressive optimization
-optimizationpasses 5
-repackageclasses ''

############################################
# ADDITIONAL HARDENING
############################################
-repackageclasses 'a'
-optimizationpasses 5
-keepattributes !SourceDebugExtension
-dontusemixedcaseclassnames

############################################
# FLATTEN PACKAGE STRUCTURE
############################################
-repackageclasses 'x'
-optimizationpasses 5
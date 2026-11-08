# Local FlutterFire Android Gradle patches

These are copies of the published `firebase_core` 5.0.0 and
`firebase_analytics` 13.0.0 packages. Their BSD licenses are retained in each
package directory. The app uses path overrides so the patch is reproducible
without modifying the global Pub cache.

Only the Android Gradle files and the `resolution: workspace` pubspec entries
were changed. The Gradle files use AGP 9 built-in Kotlin directly and set JVM
target 17. The published packages conditionally apply the old Kotlin Gradle
plugin when `android.builtInKotlin=false`; Flutter 3.47's warning scanner still
flags that declaration even when the condition is false. Recheck this local
patch when upgrading either FlutterFire package.

// Remplace android/app/src/main/kotlin/.../MainActivity.kt du projet généré
// par `flutter create` (voir SETUP.md). Adapte le `package` ci-dessous pour
// qu'il corresponde exactement à celui utilisé lors du `flutter create`
// (visible aussi dans android/app/build.gradle, applicationId).

package com.example.url_reader

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "url_reader/file_intent"
    private var methodChannel: MethodChannel? = null
    private var pendingFilePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFile" -> result.success(pendingFilePath)
                else -> result.notImplemented()
            }
        }
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val data = intent?.data ?: return
        val path = resolveRealPath(data) ?: return
        pendingFilePath = path
        methodChannel?.invokeMethod("onFileReceived", path)
    }

    /**
     * La plupart des gestionnaires de fichiers exposent un content provider
     * (content://) plutôt qu'un chemin de fichier direct : on copie donc le
     * contenu vers le cache de l'app pour obtenir un chemin exploitable côté
     * Dart (File(path).readAsBytes()).
     */
    private fun resolveRealPath(uri: Uri): String? {
        return try {
            val input = contentResolver.openInputStream(uri) ?: return null
            val fileName = "shared_${System.currentTimeMillis()}.epub"
            val outFile = File(cacheDir, fileName)
            input.use { inp -> outFile.outputStream().use { out -> inp.copyTo(out) } }
            outFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}

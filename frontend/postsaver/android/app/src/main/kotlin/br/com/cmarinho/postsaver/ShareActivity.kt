package br.com.cmarinho.postsaver

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Recebe ACTION_SEND das redes sociais e renderiza apenas o popup de salvar
 * post (entrypoint Dart [shareMain]) sobre um fundo translúcido — o app que
 * originou o compartilhamento continua visível atrás.
 */
class ShareActivity : FlutterActivity() {

    override fun getDartEntrypointFunctionName(): String = "shareMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedText" -> result.success(sharedText())
                    "close" -> {
                        result.success(null)
                        finish()
                    }
                    "openApp" -> {
                        startActivity(
                            Intent(this, MainActivity::class.java)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                        finish()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun sharedText(): String? =
        if (intent?.action == Intent.ACTION_SEND) intent.getStringExtra(Intent.EXTRA_TEXT) else null

    companion object {
        private const val CHANNEL = "br.com.cmarinho.postsaver/share"
    }
}

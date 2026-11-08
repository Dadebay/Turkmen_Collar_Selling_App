package world.nailao.video_thumbnail_plus

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class VideoThumbnailPlusPluginTest {
    @Test
    fun onMethodCall_invalidMethod_returnsNotImplemented() {
        val plugin = VideoThumbnailPlusPlugin()

        val call = MethodCall("unknownMethod", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).notImplemented()
    }

    @Test
    fun onMethodCall_file_withoutVideo_returnsError() {
        val plugin = VideoThumbnailPlusPlugin()

        val call = MethodCall("file", mapOf<String, Any>())
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(
            Mockito.eq("INVALID_ARGUMENT"),
            Mockito.eq("Video path or URL is required"),
            Mockito.isNull()
        )
    }

    @Test
    fun onMethodCall_data_withoutVideo_returnsError() {
        val plugin = VideoThumbnailPlusPlugin()

        val call = MethodCall("data", mapOf<String, Any>())
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(
            Mockito.eq("INVALID_ARGUMENT"),
            Mockito.eq("Video path or URL is required"),
            Mockito.isNull()
        )
    }
}

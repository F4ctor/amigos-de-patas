package com.acj.amigosdepatas.data

object ApiConfig {
    const val SERVER_ROOT = "http://10.0.2.2:8080/amigosdepatas_server/"
    const val BASE_URL = SERVER_ROOT + "api/"

    fun imageUrl(path: String?): String {
        if (path.isNullOrBlank()) return ""
        return if (path.startsWith("http")) path else SERVER_ROOT + path.trimStart('/')
    }
}

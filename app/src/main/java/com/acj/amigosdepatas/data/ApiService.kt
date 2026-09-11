package com.acj.amigosdepatas.data

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query
import java.util.concurrent.TimeUnit

interface ApiService {
    @POST("auth/login.php")
    suspend fun login(@Body request: LoginRequest): LoginResponse

    @POST("auth/register.php")
    suspend fun register(@Body request: RegisterRequest): ApiMessageResponse

    @GET("public/home.php")
    suspend fun getHome(): HomeResponse

    @GET("public/animals.php")
    suspend fun getAnimals(): AnimalsResponse

    @GET("public/animal.php")
    suspend fun getAnimal(@Query("id") id: Int): AnimalResponse

    @GET("public/campaigns.php")
    suspend fun getCampaigns(): CampaignsResponse

    @GET("public/news.php")
    suspend fun getNews(): NewsResponse

    @GET("public/about.php")
    suspend fun getAbout(): AboutResponse

    @POST("public/adoption_request.php")
    suspend fun sendAdoptionRequest(@Body request: AdoptionRequestBody): ApiMessageResponse
}

object ApiClient {
    private val logger = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.NONE
    }

    private val client = OkHttpClient.Builder()
        .addInterceptor(logger)
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .writeTimeout(20, TimeUnit.SECONDS)
        .build()

    val service: ApiService by lazy {
        Retrofit.Builder()
            .baseUrl(ApiConfig.BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(ApiService::class.java)
    }
}

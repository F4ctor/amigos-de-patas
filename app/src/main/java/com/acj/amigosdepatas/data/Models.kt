package com.acj.amigosdepatas.data

import com.google.gson.annotations.SerializedName

data class ApiMessageResponse(
    val success: Boolean,
    val message: String
)

data class LoginRequest(
    val email: String,
    val password: String
)

data class RegisterRequest(
    val name: String,
    val email: String,
    val phone: String,
    val password: String
)

data class MobileUser(
    val id: Int,
    val name: String,
    val email: String,
    val phone: String?
)

data class LoginResponse(
    val success: Boolean,
    val message: String,
    val user: MobileUser?
)

data class Animal(
    val id: Int,
    val name: String,
    val species: String,
    @SerializedName("age_text") val ageText: String,
    val gender: String,
    val size: String,
    val status: String,
    val description: String,
    @SerializedName("image_path") val imagePath: String?,
    val featured: Int
)

data class Campaign(
    val id: Int,
    val title: String,
    val description: String,
    @SerializedName("goal_amount") val goalAmount: Double,
    @SerializedName("raised_amount") val raisedAmount: Double,
    @SerializedName("pix_key") val pixKey: String?,
    @SerializedName("image_path") val imagePath: String?,
    val featured: Int,
    val active: Int
)

data class NewsItem(
    val id: Int,
    val title: String,
    val summary: String,
    val content: String?,
    @SerializedName("image_path") val imagePath: String?,
    @SerializedName("published_at") val publishedAt: String
)

data class SettingsData(
    @SerializedName("org_name") val orgName: String,
    val tagline: String?,
    @SerializedName("about_text") val aboutText: String?,
    @SerializedName("mission_text") val missionText: String?,
    val whatsapp: String?,
    @SerializedName("pix_key") val pixKey: String?,
    val instagram: String?,
    val address: String?,
    @SerializedName("donation_notice") val donationNotice: String?
)

data class StatsData(
    @SerializedName("animals_count") val animalsCount: Int,
    @SerializedName("campaigns_count") val campaignsCount: Int,
    @SerializedName("news_count") val newsCount: Int,
    @SerializedName("requests_count") val requestsCount: Int
)

data class HomeData(
    val settings: SettingsData,
    val stats: StatsData,
    @SerializedName("featured_animals") val featuredAnimals: List<Animal>,
    @SerializedName("featured_campaigns") val featuredCampaigns: List<Campaign>,
    @SerializedName("latest_news") val latestNews: List<NewsItem>
)

data class HomeResponse(
    val success: Boolean,
    val data: HomeData?
)

data class AnimalsResponse(
    val success: Boolean,
    val items: List<Animal>
)

data class AnimalResponse(
    val success: Boolean,
    val item: Animal?
)

data class CampaignsResponse(
    val success: Boolean,
    val items: List<Campaign>
)

data class NewsResponse(
    val success: Boolean,
    val items: List<NewsItem>
)

data class AboutResponse(
    val success: Boolean,
    val item: SettingsData?
)

data class AdoptionRequestBody(
    @SerializedName("animal_id") val animalId: Int,
    @SerializedName("full_name") val fullName: String,
    val email: String,
    val phone: String,
    val city: String,
    val message: String
)

package com.acj.amigosdepatas.data

class Repository(private val api: ApiService) {
    suspend fun login(email: String, password: String) =
        api.login(LoginRequest(email = email, password = password))

    suspend fun register(name: String, email: String, phone: String, password: String) =
        api.register(RegisterRequest(name = name, email = email, phone = phone, password = password))

    suspend fun home() = api.getHome()

    suspend fun animals() = api.getAnimals()

    suspend fun animal(id: Int) = api.getAnimal(id)

    suspend fun campaigns() = api.getCampaigns()

    suspend fun news() = api.getNews()

    suspend fun about() = api.getAbout()

    suspend fun requestAdoption(body: AdoptionRequestBody) = api.sendAdoptionRequest(body)
}

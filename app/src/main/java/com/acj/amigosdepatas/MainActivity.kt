package com.acj.amigosdepatas

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.weight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.CardDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.acj.amigosdepatas.data.AdoptionRequestBody
import com.acj.amigosdepatas.data.Animal
import com.acj.amigosdepatas.data.ApiClient
import com.acj.amigosdepatas.data.ApiConfig
import com.acj.amigosdepatas.data.Campaign
import com.acj.amigosdepatas.data.HomeData
import com.acj.amigosdepatas.data.MobileUser
import com.acj.amigosdepatas.data.NewsItem
import com.acj.amigosdepatas.data.Repository
import com.acj.amigosdepatas.data.SettingsData
import com.acj.amigosdepatas.ui.theme.AccentYellow
import com.acj.amigosdepatas.ui.theme.AmigosDePatasTheme
import com.acj.amigosdepatas.ui.theme.PrimaryGreen
import com.acj.amigosdepatas.ui.theme.SoftGreen
import com.acj.amigosdepatas.ui.theme.SoftYellow
import kotlinx.coroutines.launch
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AmigosDePatasTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    AmigosApp()
                }
            }
        }
    }
}

@Composable
fun AmigosApp() {
    val navController = rememberNavController()
    val repository = remember { Repository(ApiClient.service) }
    var currentUser by remember { mutableStateOf<MobileUser?>(null) }

    NavHost(
        navController = navController,
        startDestination = "login"
    ) {
        composable("login") {
            LoginScreen(
                repository = repository,
                onLoginSuccess = { user ->
                    currentUser = user
                    navController.navigate("home") {
                        popUpTo("login") { inclusive = true }
                    }
                },
                onRegisterClick = { navController.navigate("register") }
            )
        }

        composable("register") {
            RegisterScreen(
                repository = repository,
                onBackToLogin = { navController.popBackStack() }
            )
        }

        composable("home") {
            HomeScreen(
                currentUser = currentUser,
                repository = repository,
                onLogout = {
                    currentUser = null
                    navController.navigate("login") {
                        popUpTo("home") { inclusive = true }
                    }
                },
                onAnimalClick = { animalId ->
                    navController.navigate("animal/$animalId")
                },
                onAdoptionClick = { animalId ->
                    navController.navigate("adoption/$animalId")
                }
            )
        }

        composable(
            route = "animal/{id}",
            arguments = listOf(navArgument("id") { type = NavType.IntType })
        ) { backStackEntry ->
            val animalId = backStackEntry.arguments?.getInt("id") ?: 0
            AnimalDetailScreen(
                animalId = animalId,
                repository = repository,
                onBack = { navController.popBackStack() },
                onAdopt = { navController.navigate("adoption/$animalId") }
            )
        }

        composable(
            route = "adoption/{id}",
            arguments = listOf(navArgument("id") { type = NavType.IntType })
        ) { backStackEntry ->
            val animalId = backStackEntry.arguments?.getInt("id") ?: 0
            AdoptionScreen(
                animalId = animalId,
                repository = repository,
                currentUser = currentUser,
                onBack = { navController.popBackStack() }
            )
        }
    }
}

@Composable
fun LoginScreen(
    repository: Repository,
    onLoginSuccess: (MobileUser) -> Unit,
    onRegisterClick: () -> Unit
) {
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    var email by rememberSaveable { mutableStateOf("usuario@amigosdepatas.local") }
    var password by rememberSaveable { mutableStateOf("123456") }
    var loading by remember { mutableStateOf(false) }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF7F4EF))
                .padding(innerPadding)
                .padding(24.dp),
            verticalArrangement = Arrangement.Center
        ) {
            HeaderBlock()

            Spacer(modifier = Modifier.height(20.dp))

            Card(
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        text = "Entrar",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("E-mail") },
                        singleLine = true
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Senha") },
                        singleLine = true,
                        visualTransformation = PasswordVisualTransformation()
                    )

                    Spacer(modifier = Modifier.height(18.dp))

                    Button(
                        onClick = {
                            scope.launch {
                                loading = true
                                try {
                                    val response = repository.login(email, password)
                                    if (response.success && response.user != null) {
                                        onLoginSuccess(response.user)
                                    } else {
                                        snackbarHostState.showSnackbar(
                                            response.message.ifBlank { "Não foi possível entrar." }
                                        )
                                    }
                                } catch (e: Exception) {
                                    snackbarHostState.showSnackbar(
                                        "Falha de conexão. Verifique o servidor Apache."
                                    )
                                } finally {
                                    loading = false
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !loading
                    ) {
                        if (loading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(18.dp),
                                strokeWidth = 2.dp,
                                color = Color.White
                            )
                        } else {
                            Text("Entrar")
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    TextButton(
                        onClick = onRegisterClick,
                        modifier = Modifier.align(Alignment.End)
                    ) {
                        Text("Criar conta")
                    }
                }
            }
        }
    }
}

@Composable
fun RegisterScreen(
    repository: Repository,
    onBackToLogin: () -> Unit
) {
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    var name by rememberSaveable { mutableStateOf("") }
    var email by rememberSaveable { mutableStateOf("") }
    var phone by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var loading by remember { mutableStateOf(false) }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF7F4EF))
                .verticalScroll(rememberScrollState())
                .padding(innerPadding)
                .padding(24.dp)
        ) {
            TextButton(onClick = onBackToLogin) {
                Text("← Voltar")
            }

            Spacer(modifier = Modifier.height(12.dp))
            HeaderBlock()

            Spacer(modifier = Modifier.height(20.dp))

            Card(
                shape = RoundedCornerShape(24.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        text = "Cadastro",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Nome") }
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("E-mail") }
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = phone,
                        onValueChange = { phone = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Telefone") }
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Senha") },
                        visualTransformation = PasswordVisualTransformation()
                    )

                    Spacer(modifier = Modifier.height(18.dp))

                    Button(
                        onClick = {
                            scope.launch {
                                loading = true
                                try {
                                    val response = repository.register(name, email, phone, password)
                                    snackbarHostState.showSnackbar(response.message)
                                    if (response.success) {
                                        onBackToLogin()
                                    }
                                } catch (e: Exception) {
                                    snackbarHostState.showSnackbar("Não foi possível cadastrar agora.")
                                } finally {
                                    loading = false
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !loading
                    ) {
                        if (loading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(18.dp),
                                strokeWidth = 2.dp,
                                color = Color.White
                            )
                        } else {
                            Text("Cadastrar")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun HomeScreen(
    currentUser: MobileUser?,
    repository: Repository,
    onLogout: () -> Unit,
    onAnimalClick: (Int) -> Unit,
    onAdoptionClick: (Int) -> Unit
) {
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }

    val items = listOf(
        "Início" to "🏠",
        "Pets" to "🐾",
        "Campanhas" to "💛",
        "Notícias" to "📰",
        "Sobre" to "ℹ️"
    )

    Scaffold(
        bottomBar = {
            NavigationBar {
                items.forEachIndexed { index, item ->
                    NavigationBarItem(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        icon = { Text(item.second) },
                        label = { Text(item.first) }
                    )
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF7F4EF))
                .padding(innerPadding)
        ) {
            AppHeader(
                userName = currentUser?.name,
                onLogout = onLogout
            )

            when (selectedTab) {
                0 -> DashboardTab(repository, onAnimalClick)
                1 -> AnimalsTab(repository, onAnimalClick, onAdoptionClick)
                2 -> CampaignsTab(repository)
                3 -> NewsTab(repository)
                4 -> AboutTab(repository)
            }
        }
    }
}

@Composable
fun DashboardTab(
    repository: Repository,
    onAnimalClick: (Int) -> Unit
) {
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf("") }
    var data by remember { mutableStateOf<HomeData?>(null) }

    LaunchedEffect(Unit) {
        try {
            data = repository.home().data
        } catch (e: Exception) {
            error = "Não foi possível carregar a tela inicial."
        } finally {
            loading = false
        }
    }

    when {
        loading -> LoadingBlock()
        error.isNotBlank() -> ErrorBlock(error)
        data != null -> DashboardContent(data = data!!, onAnimalClick = onAnimalClick)
    }
}

@Composable
fun DashboardContent(
    data: HomeData,
    onAnimalClick: (Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Card(
            colors = CardDefaults.cardColors(containerColor = SoftGreen),
            shape = RoundedCornerShape(24.dp)
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                Text(
                    text = data.settings.orgName,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = data.settings.tagline ?: "Adote • Ajude • Transforme",
                    color = Color(0xFF495057)
                )
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = data.settings.donationNotice ?: "Doe via Pix e ajude a manter a ONG ativa.",
                    color = PrimaryGreen
                )
            }
        }

        SectionTitle("Resumo")
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatMiniCard("Pets", data.stats.animalsCount, Modifier.weight(1f))
            StatMiniCard("Campanhas", data.stats.campaignsCount, Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatMiniCard("Notícias", data.stats.newsCount, Modifier.weight(1f))
            StatMiniCard("Pedidos", data.stats.requestsCount, Modifier.weight(1f))
        }

        SectionTitle("Pets em destaque")
        data.featuredAnimals.forEach { animal ->
            AnimalCard(
                animal = animal,
                onClick = { onAnimalClick(animal.id) }
            )
        }

        SectionTitle("Campanhas em destaque")
        data.featuredCampaigns.forEach { campaign ->
            CampaignCard(campaign = campaign)
        }

        SectionTitle("Últimas notícias")
        data.latestNews.forEach { news ->
            NewsCard(news = news)
        }
    }
}

@Composable
fun AnimalsTab(
    repository: Repository,
    onAnimalClick: (Int) -> Unit,
    onAdoptionClick: (Int) -> Unit
) {
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf("") }
    var query by rememberSaveable { mutableStateOf("") }
    var items by remember { mutableStateOf<List<Animal>>(emptyList()) }

    LaunchedEffect(Unit) {
        try {
            items = repository.animals().items
        } catch (e: Exception) {
            error = "Não foi possível carregar os animais."
        } finally {
            loading = false
        }
    }

    when {
        loading -> LoadingBlock()
        error.isNotBlank() -> ErrorBlock(error)
        else -> {
            val filtered = items.filter {
                it.name.contains(query, true) ||
                    it.species.contains(query, true) ||
                    it.status.contains(query, true)
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Buscar por nome, espécie ou status") }
                )

                filtered.forEach { animal ->
                    AnimalCard(
                        animal = animal,
                        onClick = { onAnimalClick(animal.id) },
                        actionLabel = "Quero adotar",
                        onActionClick = { onAdoptionClick(animal.id) }
                    )
                }

                if (filtered.isEmpty()) {
                    EmptyBlock("Nenhum animal encontrado para o filtro informado.")
                }
            }
        }
    }
}

@Composable
fun CampaignsTab(repository: Repository) {
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf("") }
    var items by remember { mutableStateOf<List<Campaign>>(emptyList()) }

    LaunchedEffect(Unit) {
        try {
            items = repository.campaigns().items
        } catch (e: Exception) {
            error = "Não foi possível carregar as campanhas."
        } finally {
            loading = false
        }
    }

    when {
        loading -> LoadingBlock()
        error.isNotBlank() -> ErrorBlock(error)
        else -> Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items.forEach { campaign ->
                CampaignCard(campaign)
            }

            if (items.isEmpty()) {
                EmptyBlock("Nenhuma campanha disponível.")
            }
        }
    }
}

@Composable
fun NewsTab(repository: Repository) {
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf("") }
    var items by remember { mutableStateOf<List<NewsItem>>(emptyList()) }

    LaunchedEffect(Unit) {
        try {
            items = repository.news().items
        } catch (e: Exception) {
            error = "Não foi possível carregar as notícias."
        } finally {
            loading = false
        }
    }

    when {
        loading -> LoadingBlock()
        error.isNotBlank() -> ErrorBlock(error)
        else -> Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items.forEach { news ->
                NewsCard(news)
            }

            if (items.isEmpty()) {
                EmptyBlock("Nenhuma notícia cadastrada.")
            }
        }
    }
}

@Composable
fun AboutTab(repository: Repository) {
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf("") }
    var item by remember { mutableStateOf<SettingsData?>(null) }

    LaunchedEffect(Unit) {
        try {
            item = repository.about().item
        } catch (e: Exception) {
            error = "Não foi possível carregar os dados da ONG."
        } finally {
            loading = false
        }
    }

    when {
        loading -> LoadingBlock()
        error.isNotBlank() -> ErrorBlock(error)
        item != null -> AboutContent(item!!)
    }
}

@Composable
fun AboutContent(item: SettingsData) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Card(
            colors = CardDefaults.cardColors(containerColor = SoftGreen),
            shape = RoundedCornerShape(24.dp)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text(
                    text = item.orgName,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(text = item.tagline ?: "", color = Color(0xFF4B5563))
            }
        }

        InfoCard("Quem somos", item.aboutText ?: "Sem descrição.")
        InfoCard("Nosso propósito", item.missionText ?: "Sem propósito cadastrado.")
        InfoCard("WhatsApp", item.whatsapp ?: "-")
        InfoCard("Instagram", item.instagram ?: "-")
        InfoCard("Chave Pix", item.pixKey ?: "-")
        InfoCard("Endereço", item.address ?: "-")
    }
}

@Composable
fun AnimalDetailScreen(
    animalId: Int,
    repository: Repository,
    onBack: () -> Unit,
    onAdopt: () -> Unit
) {
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf("") }
    var animal by remember { mutableStateOf<Animal?>(null) }

    LaunchedEffect(animalId) {
        try {
            animal = repository.animal(animalId).item
        } catch (e: Exception) {
            error = "Não foi possível carregar o animal."
        } finally {
            loading = false
        }
    }

    Scaffold { innerPadding ->
        when {
            loading -> LoadingBlock(modifier = Modifier.padding(innerPadding))
            error.isNotBlank() -> ErrorBlock(error, modifier = Modifier.padding(innerPadding))
            animal != null -> Column(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xFFF7F4EF))
                    .verticalScroll(rememberScrollState())
                    .padding(innerPadding)
                    .padding(16.dp)
            ) {
                TextButton(onClick = onBack) { Text("← Voltar") }

                Spacer(modifier = Modifier.height(8.dp))

                RemoteImage(
                    path = animal!!.imagePath,
                    contentDescription = animal!!.name,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(240.dp)
                        .clip(RoundedCornerShape(24.dp))
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = animal!!.name,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(10.dp))
                ChipsRow(listOf(animal!!.species, animal!!.ageText, animal!!.gender, animal!!.size))

                Spacer(modifier = Modifier.height(12.dp))
                InfoCard("Status", animal!!.status)
                InfoCard("Descrição", animal!!.description)

                Spacer(modifier = Modifier.height(10.dp))
                Button(
                    onClick = onAdopt,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Solicitar adoção")
                }
            }
        }
    }
}

@Composable
fun AdoptionScreen(
    animalId: Int,
    repository: Repository,
    currentUser: MobileUser?,
    onBack: () -> Unit
) {
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    var fullName by rememberSaveable(currentUser?.name) { mutableStateOf(currentUser?.name ?: "") }
    var email by rememberSaveable(currentUser?.email) { mutableStateOf(currentUser?.email ?: "") }
    var phone by rememberSaveable(currentUser?.phone) { mutableStateOf(currentUser?.phone ?: "") }
    var city by rememberSaveable { mutableStateOf("") }
    var message by rememberSaveable { mutableStateOf("") }
    var loading by remember { mutableStateOf(false) }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF7F4EF))
                .verticalScroll(rememberScrollState())
                .padding(innerPadding)
                .padding(16.dp)
        ) {
            TextButton(onClick = onBack) { Text("← Voltar") }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Solicitar adoção",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "Preencha seus dados para enviar o interesse à ONG.",
                color = Color(0xFF6B7280)
            )

            Spacer(modifier = Modifier.height(18.dp))

            Card(shape = RoundedCornerShape(24.dp)) {
                Column(modifier = Modifier.padding(20.dp)) {
                    OutlinedTextField(
                        value = fullName,
                        onValueChange = { fullName = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Nome completo") }
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("E-mail") }
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = phone,
                        onValueChange = { phone = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Telefone") }
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = city,
                        onValueChange = { city = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Cidade") }
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = message,
                        onValueChange = { message = it },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(140.dp),
                        label = { Text("Mensagem") }
                    )

                    Spacer(modifier = Modifier.height(18.dp))

                    Button(
                        onClick = {
                            scope.launch {
                                loading = true
                                try {
                                    val response = repository.requestAdoption(
                                        AdoptionRequestBody(
                                            animalId = animalId,
                                            fullName = fullName,
                                            email = email,
                                            phone = phone,
                                            city = city,
                                            message = message
                                        )
                                    )
                                    snackbarHostState.showSnackbar(response.message)
                                    if (response.success) {
                                        onBack()
                                    }
                                } catch (e: Exception) {
                                    snackbarHostState.showSnackbar("Não foi possível enviar sua solicitação.")
                                } finally {
                                    loading = false
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !loading
                    ) {
                        if (loading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(18.dp),
                                strokeWidth = 2.dp,
                                color = Color.White
                            )
                        } else {
                            Text("Enviar solicitação")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun HeaderBlock() {
    Column {
        Text(
            text = "Amigos de Patas",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = PrimaryGreen
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = "Adoção responsável, notícias da ONG e campanhas solidárias em um só lugar.",
            color = Color(0xFF6B7280)
        )
    }
}

@Composable
fun AppHeader(
    userName: String?,
    onLogout: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = SoftGreen)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Olá, ${userName ?: "visitante"}!",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Use o app para acompanhar pets, campanhas e notícias.",
                    color = Color(0xFF4B5563)
                )
            }

            TextButton(onClick = onLogout) {
                Text("Sair")
            }
        }
    }
}

@Composable
fun AnimalCard(
    animal: Animal,
    onClick: () -> Unit,
    actionLabel: String? = null,
    onActionClick: (() -> Unit)? = null
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column {
            RemoteImage(
                path = animal.imagePath,
                contentDescription = animal.name,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(190.dp)
            )

            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = animal.name,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(6.dp))
                ChipsRow(listOf(animal.species, animal.ageText, animal.size))
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = animal.description,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                    color = Color(0xFF4B5563)
                )
                Spacer(modifier = Modifier.height(10.dp))
                FilterChip(
                    selected = false,
                    onClick = { },
                    label = { Text(animal.status) }
                )

                if (actionLabel != null && onActionClick != null) {
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedButton(
                        onClick = onActionClick,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(actionLabel)
                    }
                }
            }
        }
    }
}

@Composable
fun CampaignCard(campaign: Campaign) {
    val progress = if (campaign.goalAmount > 0) {
        (campaign.raisedAmount / campaign.goalAmount).coerceIn(0.0, 1.0)
    } else 0.0

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp)
    ) {
        Column {
            RemoteImage(
                path = campaign.imagePath,
                contentDescription = campaign.title,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(190.dp)
            )

            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = campaign.title,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(campaign.description, color = Color(0xFF4B5563))
                Spacer(modifier = Modifier.height(12.dp))

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(12.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(Color(0xFFE5E7EB))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(progress.toFloat())
                            .height(12.dp)
                            .clip(RoundedCornerShape(999.dp))
                            .background(AccentYellow)
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "Arrecadado: R$ ${"%.2f".format(campaign.raisedAmount)} de R$ ${"%.2f".format(campaign.goalAmount)}",
                    fontWeight = FontWeight.SemiBold
                )

                Spacer(modifier = Modifier.height(6.dp))
                Text("Pix: ${campaign.pixKey ?: "não informado"}", color = PrimaryGreen)
            }
        }
    }
}

@Composable
fun NewsCard(news: NewsItem) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp)
    ) {
        Column {
            RemoteImage(
                path = news.imagePath,
                contentDescription = news.title,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(190.dp)
            )

            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = news.title,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(news.summary, color = Color(0xFF4B5563))
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Publicado em ${news.publishedAt.take(10)}",
                    color = PrimaryGreen,
                    style = MaterialTheme.typography.labelLarge
                )
            }
        }
    }
}

@Composable
fun InfoCard(title: String, value: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(22.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(6.dp))
            Text(value, color = Color(0xFF4B5563))
        }
    }
}

@Composable
fun RemoteImage(
    path: String?,
    contentDescription: String,
    modifier: Modifier = Modifier
) {
    if (path.isNullOrBlank()) {
        Box(
            modifier = modifier.background(SoftYellow),
            contentAlignment = Alignment.Center
        ) {
            Text("Sem imagem", color = PrimaryGreen)
        }
    } else {
        AsyncImage(
            model = ApiConfig.imageUrl(path),
            contentDescription = contentDescription,
            contentScale = ContentScale.Crop,
            modifier = modifier.background(Color(0xFFE5E7EB))
        )
    }
}

@Composable
fun ChipsRow(values: List<String>) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        values.take(3).forEach { value ->
            Surface(
                color = SoftYellow,
                shape = RoundedCornerShape(999.dp)
            ) {
                Text(
                    text = value,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    color = PrimaryGreen,
                    style = MaterialTheme.typography.labelLarge
                )
            }
        }
    }
}

@Composable
fun StatMiniCard(
    label: String,
    value: Int,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = value.toString(),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = PrimaryGreen
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(label, color = Color(0xFF4B5563))
        }
    }
}

@Composable
fun SectionTitle(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleLarge,
        fontWeight = FontWeight.Bold
    )
}

@Composable
fun LoadingBlock(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(color = PrimaryGreen)
    }
}

@Composable
fun ErrorBlock(message: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(message, color = Color(0xFFB00020))
    }
}

@Composable
fun EmptyBlock(message: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White, RoundedCornerShape(20.dp))
            .padding(20.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(message, color = Color(0xFF6B7280))
    }
}

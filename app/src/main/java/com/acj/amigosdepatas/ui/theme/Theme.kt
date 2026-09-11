package com.acj.amigosdepatas.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = PrimaryGreen,
    secondary = AccentYellow,
    tertiary = PrimaryGreenDark,
    background = BackgroundCream,
    surface = SurfaceWhite
)

private val DarkColors = darkColorScheme(
    primary = PrimaryGreen,
    secondary = AccentYellow,
    tertiary = PrimaryGreenDark
)

@Composable
fun AmigosDePatasTheme(
    darkTheme: Boolean = false,
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) DarkColors else LightColors

    MaterialTheme(
        colorScheme = colors,
        typography = Typography,
        content = content
    )
}

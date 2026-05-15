# ============================================================
# verify_setup.R — Equipo 3 (post-rescate)
# Corre esto ANTES de renderizar el .qmd.
# Confirma que paquetes, datos y los modelos clave del plan de
# rescate funcionan. Si esto termina sin errores, el .qmd renderiza.
# ============================================================

cat("\n========== VERIFY SETUP — Equipo 3 (Rescue Build) ==========\n\n")

# ---- 1. Paquetes ----
need_pkgs <- c("tidyverse", "tsibble", "feasts", "fable", "fabletools", "patchwork")
missing_pkgs <- setdiff(need_pkgs, rownames(installed.packages()))

if (length(missing_pkgs) > 0) {
  cat("Falta instalar:\n")
  cat(sprintf('  install.packages(c("%s"))\n', paste(missing_pkgs, collapse = '", "')))
  stop("Instala los paquetes faltantes y vuelve a correr este script.")
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(tsibble)
  library(feasts)
  library(fable)
  library(fabletools)
})
cat("[OK] Paquetes cargados\n")

# ---- 2. Datos ----
# Soporta el path que usas en tu entorno (data/processed/) y fallback al raíz
data_paths <- c("data/processed/deli_data.RData", "deli_data.RData")
data_loaded <- FALSE
for (p in data_paths) {
  if (file.exists(p)) {
    load(p)
    data_loaded <- TRUE
    cat(sprintf("[OK] Datos cargados desde: %s\n", p))
    break
  }
}
if (!data_loaded) {
  stop("No encuentro deli_data.RData ni en 'data/processed/' ni en el raíz. ",
       "Working dir actual: ", getwd())
}
stopifnot(exists("ventas_semana"), exists("ventas_mes"))
cat(sprintf("    ventas_semana: %d obs · ventas_mes: %d obs\n",
            nrow(ventas_semana), nrow(ventas_mes)))

# ---- 3. Test Parte 1 (ensemble de 2 ARIMAs sobre log — RESCUE BUILD) ----
cat("\n--- Test Parte 1 (ensemble de 2 ARIMAs sobre log, sin ETS) ---\n")

ws_clean <- ventas_semana |> filter(fecha >= yearweek("2021 W01"))
ws_train_check <- ws_clean |> filter(fecha < yearweek("2025 W01"))

fit_check <- ws_train_check |>
  model(
    snaive      = SNAIVE(total ~ lag("year")),
    baseline    = decomposition_model(STL(total, robust = TRUE),
                                      RW(season_adjust ~ drift())),
    arima_f5    = ARIMA(log(total) ~ fourier(K = 5) + PDQ(0,0,0)),
    arima011_f5 = ARIMA(log(total) ~ pdq(0,1,1) + fourier(K = 5) + PDQ(0,0,0))
  ) |>
  mutate(equipo_3 = (arima_f5 + arima011_f5) / 2)

cat("[OK] mable creado (ensemble de 2 ARIMAs)\n")

fc_check <- fit_check |> forecast(h = 19)
cat(sprintf("[OK] forecast(h=19) corrió, %d filas\n", nrow(fc_check)))

acc_check <- fc_check |>
  accuracy(ws_clean) |>
  select(.model, MAPE, RMSSE) |>
  arrange(MAPE)
print(acc_check)

baseline_mape <- acc_check |> filter(.model == "baseline") |> pull(MAPE)
team_mape     <- acc_check |> filter(.model == "equipo_3") |> pull(MAPE)
cat(sprintf("\n   equipo_3 MAPE: %.2f%%   |   baseline MAPE: %.2f%%   |   %s\n",
            team_mape, baseline_mape,
            if (team_mape < baseline_mape) "[OK] Vencemos el baseline en P1" else "[!] NO vence baseline"))

# ---- 4. Test Parte 2 (STL+Drift+SNAIVE reconciliado con mint_shrink — RESCUE BUILD) ----
cat("\n--- Test Parte 2 (decomposition_model(STL, RW(~drift)) + mint_shrink) ---\n")

vm_train_check <- ventas_mes |> filter(fecha < yearmonth("2024 May"))

fit2_check <- vm_train_check |>
  model(
    snaive = SNAIVE(total ~ lag("year")),
    base   = decomposition_model(
               STL(total, robust = TRUE),
               RW(season_adjust ~ drift())
             )
  ) |>
  reconcile(
    snaive_bu = bottom_up(snaive),
    equipo_3  = min_trace(base, method = "mint_shrink"),
    base_bu   = bottom_up(base)
  )

cat("[OK] mable jerárquico creado con reconcile()\n")

fc2_check <- fit2_check |> forecast(h = 12)
cat(sprintf("[OK] forecast jerárquico h=12: %d filas totales\n", nrow(fc2_check)))

acc2_check <- fc2_check |>
  accuracy(ventas_mes, measures = list(RMSSE = RMSSE)) |>
  mutate(level = case_when(
    is_aggregated(nivel_1) & is_aggregated(nivel_2)   ~ "Total",
    !is_aggregated(nivel_1) & is_aggregated(nivel_2)  ~ "nivel_1",
    TRUE                                              ~ "nivel_2"
  )) |>
  group_by(.model, level) |>
  summarise(RMSSE = mean(RMSSE, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = level, values_from = RMSSE) |>
  mutate(ALL_mean = (Total + nivel_1 + nivel_2) / 3) |>
  arrange(ALL_mean)
print(acc2_check)

equipo_3_rmsse <- acc2_check |> filter(.model == "equipo_3") |> pull(ALL_mean)
base_bu_rmsse  <- acc2_check |> filter(.model == "base_bu")  |> pull(ALL_mean)
snaive_rmsse   <- acc2_check |> filter(.model == "snaive")   |> pull(ALL_mean)

cat(sprintf("\n   equipo_3 RMSSE_ALL = %.3f\n", equipo_3_rmsse))
cat(sprintf("   base_bu RMSSE_ALL  = %.3f  (Plan B si equipo_3 < base_bu)\n", base_bu_rmsse))
cat(sprintf("   snaive RMSSE_ALL   = %.3f\n", snaive_rmsse))

if (equipo_3_rmsse <= base_bu_rmsse) {
  cat("   [OK] equipo_3 (mint_shrink) >= base_bu — mantener mint_shrink\n")
} else {
  cat("   [!]  equipo_3 (mint_shrink) > base_bu — considerar cambiar a bottom_up(base) en p2-final-fit\n")
}

# ---- 5. Verificación de naming convention ----
cat("\n--- Verificación naming convention ---\n")
g_sample <- fc_check |> filter(.model == "equipo_3")
h_sample <- fc2_check |> filter(.model == "equipo_3")
stopifnot(unique(g_sample$.model) == "equipo_3")
stopifnot(unique(h_sample$.model) == "equipo_3")
cat("[OK] El .model en ambos forecasts es exactamente 'equipo_3'\n")

# ---- 6. Verificar que la carpeta assignments/ existe ----
if (!dir.exists("assignments")) {
  cat("[!] La carpeta 'assignments/' no existe. Créala con:\n")
  cat("    dir.create('assignments')\n")
} else {
  cat("[OK] Carpeta 'assignments/' lista para los .RData\n")
}

cat("\n========== TODO OK — Puedes renderizar el .qmd ==========\n")
cat("Render: quarto render equipo_3_project.qmd\n\n")

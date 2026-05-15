# ============================================================
# verify_setup.R — Equipo 3
# Corre esto ANTES de renderizar el .qmd.
# Confirma que paquetes, datos y los modelos clave funcionan.
# Si esto termina sin errores, el .qmd va a renderizar bien.
# ============================================================

cat("\n========== VERIFY SETUP — Equipo 3 ==========\n\n")

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
if (!file.exists("data/processed/deli_data.RData")) {
  stop("No encuentro deli_data.RData en el directorio referido: ",
       getwd(), ". Mueve el archivo o haz setwd() al lugar correcto.")
}
load("data/processed/deli_data.RData")
stopifnot(exists("ventas_semana"), exists("ventas_mes"))
cat(sprintf("[OK] Datos cargados (ventas_semana: %d obs, ventas_mes: %d obs)\n",
            nrow(ventas_semana), nrow(ventas_mes)))

# ---- 3. Test mínimo Parte 1 (ensemble de 3 sobre log) ----
cat("\n--- Test Parte 1 (ARIMA+Fourier + ARIMA(0,1,1)+Fourier + ETS sobre log) ---\n")

ws_clean <- ventas_semana |> filter(fecha >= yearweek("2021 W01"))

ws_train_check <- ws_clean |> filter(fecha < yearweek("2025 W01"))

fit_check <- ws_train_check |>
  model(
    snaive      = SNAIVE(total ~ lag("year")),
    baseline    = decomposition_model(STL(total, robust = TRUE),
                                      RW(season_adjust ~ drift())),
    arima_f5    = ARIMA(log(total) ~ fourier(K = 5) + PDQ(0,0,0)),
    arima011_f5 = ARIMA(log(total) ~ pdq(0,1,1) + fourier(K = 5) + PDQ(0,0,0)),
    ets         = ETS(log(total))
  ) |>
  mutate(equipo_3 = (arima_f5 + arima011_f5 + ets) / 3)

cat("[OK] mable creado\n")

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
            if (team_mape < baseline_mape) "[OK] Vencemos el baseline" else "[!] No vencemos baseline"))

# ---- 4. Test mínimo Parte 2 (ETS Ad + mint_shrink) ----
cat("\n--- Test Parte 2 (ETS damped + min_trace mint_shrink) ---\n")

vm_train_check <- ventas_mes |> filter(fecha < yearmonth("2024 May"))

fit2_check <- vm_train_check |>
  model(base = ETS(total ~ trend("Ad"))) |>
  reconcile(equipo_3 = min_trace(base, method = "mint_shrink"))

fc2_check <- fit2_check |>
  forecast(h = 12) |>
  filter(.model == "equipo_3")

cat(sprintf("[OK] forecast jerárquico h=12: %d filas\n", nrow(fc2_check)))

acc2_check <- fit2_check |>
  forecast(h = 12) |>
  accuracy(ventas_mes, measures = list(RMSSE = RMSSE)) |>
  mutate(level = case_when(
    is_aggregated(nivel_1) & is_aggregated(nivel_2)   ~ "Total",
    !is_aggregated(nivel_1) & is_aggregated(nivel_2)  ~ "nivel_1",
    TRUE                                              ~ "nivel_2"
  )) |>
  group_by(.model, level) |>
  summarise(RMSSE = mean(RMSSE, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = level, values_from = RMSSE) |>
  mutate(ALL = (Total + nivel_1 + nivel_2) / 3)
print(acc2_check)

# ---- 5. Confirma naming ----
cat("\n--- Verificación de naming convention ---\n")
stopifnot(unique(fc_check |> filter(.model == "equipo_3") |> pull(.model)) == "equipo_3")
stopifnot(unique(fc2_check$.model) == "equipo_3")
cat("[OK] El .model en ambos forecasts es exactamente 'equipo_3'\n")

cat("\n========== TODO OK — Puedes renderizar el .qmd ==========\n")
cat("Render: quarto render assignments/equipo_3_project.qmd --execute-dir .\n")

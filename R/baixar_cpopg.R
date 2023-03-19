#processos <- union(santander1$processo, santander2$processo)
#saveRDS(processos, "data/processos_santander.rds")
processos <- readRDS(here::here("data/processos_santander.rds")) ## usa o here para nao dar problema acerca do diretorio em que o script esta salvo
processos <- split(processos, ceiling(seq_along(processos)/1000))
purrr::walk(processos,~{
  tjsp::tjsp_autenticar()
  tjsp::tjsp_baixar_cpopg(.x,diretorio = |here::here("data-raw/cpopg")) #.x e para iterar entre os grupos de 1000
  
})
library(tjsp)
arquivos <- list.files("data-raw/cpopg", full.names = TRUE)
dados <- tjsp_ler_dados_cpopg(arquivos)
partes <- tjsp_ler_partes(arquivos)
movimentacao <- tjsp_ler_movimentacao(arquivos)

#calcular tempo do processo em dias
library(JurisMiner)
movimentacao <- movimentacao |> 
  tempo_movimentacao()

library(tidyverse)
tempo_processo <- movimentacao |> 
  group_by(processo) |> 
  summarise(tempo = max(decorrencia_acumulada))

partes |> 
  count(tipo_parte)

partes <- partes |> 
  filter(str_detect(tipo_parte, "^Req"))

partes <- partes |> 
  mutate(tipo_parte = case_when(
    str_d1etect(tipo_parte, "d") ~ "reqd", 
    TRUE ~ "reqt" 
  ))

p <- partes |> 
  select(processo, tipo_parte, parte) |> 
  pivot_wider(names_from = "tipo_parte", values_from = "parte")

rqte_santander <- partes |> 
  filter(tipo_parte == "reqd", str_detect(parte, "(?i)santander"))

dados <- dados |> 
  semi_join(santander, by = "processo")
  
library(tidyverse)
library(rvest)

gen_xy <- function(text) {
  
  path_dt <- separate_rows(tibble(text = text), text, sep = "\\|") %>%
    separate(text, into = c("path_x", "path_y"), sep = ",") %>%
    distinct() %>% 
    mutate_all(as.numeric) %>%
    mutate(rel_x = path_x/200,
           rel_y = scales::rescale(path_y, c(-0.8, 0.8), c(0, 100)),
           round_x = round(rel_x, 2))
  
  date_lookup <- tibble(
    date = seq(ymd(20200223), ymd(20200405), "day"), 
    x = scales::rescale(1:43, c(0,1)), 
    round_x = round(x, 2)) %>%
    select(date, round_x)
  
  path_dt <- path_dt %>% left_join(date_lookup, by = "round_x") %>%
    select(date, value = rel_y)
  
  return(path_dt)
  
}

entity_assign <- function(base_x, base_y) {
  
  base_x <- round(as.numeric(base_x))
  base_y <- round(as.numeric(base_y))
  
  entity <- case_when(
    base_x == 205 & base_y == 360 ~ "retail_recr",
    base_x == 205 & base_y == 477 ~ "grocery_pharm",
    base_x == 205 & base_y == 594 ~ "parks",
    base_x == 190 & base_y ==  53 ~ "transit",
    base_x == 190 & base_y == 170 ~ "workplace",
    base_x == 190 & base_y == 287 ~ "residential",
    base_x ==  70 & base_y == 133 ~ "retail_recr",
    base_x == 245 & base_y == 133 ~ "grocery_pharm",
    base_x == 419 & base_y == 133 ~ "parks",
    base_x ==  70 & base_y == 271 ~ "transit",
    base_x == 245 & base_y == 271 ~ "workplace",
    base_x == 419 & base_y == 271 ~ "residential",
    base_x ==  70 & base_y == 460 ~ "retail_recr",
    base_x == 245 & base_y == 460 ~ "grocery_pharm",
    base_x == 419 & base_y == 460 ~ "parks",
    base_x ==  70 & base_y == 598 ~ "transit",
    base_x == 245 & base_y == 598 ~ "workplace",
    base_x == 419 & base_y == 598 ~ "residential",
  )
  
  return(entity)
  
}

position_assign <- function(base_x, base_y) {
  
  base_x <- round(as.numeric(base_x))
  base_y <- round(as.numeric(base_y))
  
  position <- case_when(
    base_x == 190 | base_x == 205 ~ "overall",
    base_y == 133 | base_y == 271 ~ "upper",
    base_y == 460 | base_y == 598 ~ "lower",
  )
  
  return(position)
  
}

svg_data <- xml2::read_html("~/Desktop/pdf2svg_test/extract.svg")

svg_paths <- svg_data %>% 
  html_nodes("path") %>% 
  html_attrs() %>%
  map_dfr(bind_rows, .id = "listID")

dt_1 <- svg_paths %>% filter(
  str_detect(style, "rgb\\(25.878906\\%,52.159119\\%,95.689392\\%\\)")) %>%
  drop_na(transform) %>%
  mutate(transformdat = str_remove_all(transform, "matrix\\(|\\)")) %>%
  separate(transformdat, into = c(NA, NA, NA, NA, "base_x", "base_y"), sep =",") %>%
  select(base_x, base_y, d) %>%
  mutate(
    nd = str_replace(d,"^M[ |-]+\\d+\\.\\d+ \\d+.\\d+", "0 50") %>%
      str_trim() %>%
      str_replace_all(" [L|M|Z] ", "|") %>%
      str_replace_all(" ", ","),
    coords = map(nd, gen_xy))


svg_data2 <- xml2::read_html("~/Desktop/pdf2svg_test/page40.svg")

svg_paths2 <- svg_data2 %>% 
  html_nodes("path") %>% 
  html_attrs() %>%
  map_dfr(bind_rows, .id = "listID")

dt2 <- svg_paths2 %>% filter(
  str_detect(style, "rgb\\(25.878906\\%,52.159119\\%,95.689392\\%\\)")) %>%
  drop_na(transform) %>%
  mutate(transformdat = str_remove_all(transform, "matrix\\(|\\)")) %>%
  separate(transformdat, into = c(NA, NA, NA, NA, "base_x", "base_y"), sep =",") %>%
  select(base_x, base_y, d) %>%
  mutate(
    nd = str_replace(d,"^M[ |-]+\\d+\\.\\d+ \\d+.\\d+", "0 50") %>%
      str_trim() %>%
      str_replace_all(" [L|M|(M)] ", "|") %>%
      str_replace_all(" ", ","),
    coords = map(nd, gen_xy),
    entity = map2_chr(base_x, base_y, entity_assign),
    position = map_chr(base_y, position_assign))


svg_data_p1 <- xml2::read_html("~/Desktop/pdf2svg_test/page1.svg")

svg_paths_p1 <- svg_data_p1 %>% 
  html_nodes("path") %>% 
  html_attrs() %>%
  map_dfr(bind_rows, .id = "listID")

dt_p1 <- svg_paths_p1 %>% filter(
  str_detect(style, "rgb\\(25.878906\\%,52.159119\\%,95.689392\\%\\)")) %>%
  drop_na(transform) %>%
  mutate(transformdat = str_remove_all(transform, "matrix\\(|\\)")) %>%
  separate(transformdat, into = c(NA, NA, NA, NA, "base_x", "base_y"), sep =",") %>%
  select(base_x, base_y, d) %>%
  mutate(
    nd = str_replace(d,"^M[ |-]+\\d+\\.\\d+ \\d+.\\d+", "0 50") %>%
      str_trim() %>%
      str_replace_all(" [L|M|(M)] ", "|") %>%
      str_replace_all(" ", ","),
    coords = map(nd, gen_xy),
    entity = map2_chr(base_x, base_y, entity_assign),
    position = map2_chr(base_x, base_y, position_assign))

svg_data_p2 <- xml2::read_html("~/Desktop/pdf2svg_test/page2.svg")

svg_paths_p2 <- svg_data_p2 %>% 
  html_nodes("path") %>% 
  html_attrs() %>%
  map_dfr(bind_rows, .id = "listID")

dt_p2 <- svg_paths_p2 %>% filter(
  str_detect(style, "rgb\\(25.878906\\%,52.159119\\%,95.689392\\%\\)")) %>%
  mutate(transformdat = str_remove_all(transform, "matrix\\(|\\)")) %>%
  separate(transformdat, into = c(NA, NA, NA, NA, "base_x", "base_y"), sep =",") %>%
  drop_na(transform) %>%
  select(base_x, base_y, d) %>%
  mutate(
    nd = str_replace(d,"^M[ |-]+\\d+\\.\\d+ \\d+.\\d+", "0 50") %>%
      str_trim() %>%
      str_replace_all(" [L|M|(M)] ", "|") %>%
      str_replace_all(" ", ","),
    coords = map(nd, gen_xy),
entity = map2_chr(base_x, base_y, entity_assign),
position = map2_chr(base_x, base_y, position_assign))

svgdt <- xml2::read_html("/var/folders/x7/94g4gp_s0jlcgg39ln09yq0w0000gn/T//RtmpM5NzW4/file_2_.svg")
svgpth <- svgdt %>% 
  html_nodes("path") %>% 
  html_attrs() %>%
  map_dfr(bind_rows) %>%
  drop_na(transform) %>%
  filter(str_detect(style, "rgb\\(25.878906\\%,52.159119\\%,95.689392\\%\\)")) %>%
  mutate(transformdat = str_remove_all(transform, "matrix\\(|\\)")) %>%
  separate(transformdat, into = c(NA, NA, NA, NA, "base_x", "base_y"), sep = ",") %>%
  select(base_x, base_y, d)

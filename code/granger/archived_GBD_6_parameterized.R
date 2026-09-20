# Parameterized archival script: statistical operations and legacy map retained.
# Usage: Rscript archived_GBD_6_parameterized.R INPUT_DIR OUTPUT_DIR [--render-map]
# Offline only. No downloading, authentication, scraping, or package installation.
# IMPORTANT: In the three-variable VAR, IHD source is jointly tested against
# DD AND SDI equations; DD source is jointly tested against IHD AND SDI.
# Historical IHD-to-DD/DD-to-IHD column/category labels are legacy shorthand,
# not valid evidence of equation-specific direction. All results are ecological.
# The two-variable/no-SDI analysis follows the three-variable primary analysis.
# The map block retains historical labels for archival reproduction only.
# Existing published Figure 5 is not replaced by this optional rendered output.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Provide INPUT_DIR OUTPUT_DIR [--render-map]")
input_dir <- normalizePath(args[1], mustWork = TRUE)
output_dir <- args[2]
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
render_map <- "--render-map" %in% args

library(dplyr)
library(tidyr)
library(vars)
library(vroom)

# 1. 读入数据（宽表，行是国家，列是val_1992, ..., val_2021）
ihd <- vroom::vroom(file.path(input_dir, "IHD_1992_2021_matrix.csv"))
dd  <- vroom::vroom(file.path(input_dir, "DD_1992_2021_matrix.csv"))
sdi <- vroom::vroom(file.path(input_dir, "SDI_1992_2021_matrix.csv"))

# 2. 转成长表（gather/melt），只保留location_name和年份+数值
ihd_long <- ihd %>%
  pivot_longer(
    cols = starts_with("val_"),
    names_to = "year",
    names_prefix = "val_",
    values_to = "IHD_val"
  ) %>%
  mutate(year = as.integer(year))

dd_long <- dd %>%
  pivot_longer(
    cols = starts_with("val_"),
    names_to = "year",
    names_prefix = "val_",
    values_to = "DD_val"
  ) %>%
  mutate(year = as.integer(year))

sdi_long <- sdi %>%
  pivot_longer(
    cols = starts_with("val_"),
    names_to = "year",
    names_prefix = "val_",
    values_to = "SDI_val"
  ) %>%
  mutate(year = as.integer(year))

# 3. 合并到一个表
df_all <- ihd_long %>%
  left_join(dd_long,  by = c("location_name", "year")) %>%
  left_join(sdi_long, by = c("location_name", "year"))

# 4. 批量VAR+Granger（只按国家）
granger_var_by_country <- function(df, max_p = 2){
  df <- df %>% arrange(year)
  # 要求无NA且年份数量足够
  if(any(is.na(df$IHD_val)) | any(is.na(df$DD_val)) | any(is.na(df$SDI_val)) | nrow(df) < (max_p+1)) {
    return(tibble(IHD_to_DD_p = NA, DD_to_IHD_p = NA, lag = NA))
  }
  # 自动选阶数
  p_sel <- min(VARselect(df[,c("IHD_val", "DD_val", "SDI_val")], lag.max = max_p)$selection["AIC(n)"], max_p)
  # 建模+因果检验
  res <- tryCatch({
    model <- VAR(df[,c("IHD_val", "DD_val", "SDI_val")], p = p_sel, type = "const")
    ihd2dd <- causality(model, cause = "IHD_val")$Granger$p.value
    dd2ihd <- causality(model, cause = "DD_val")$Granger$p.value
    tibble(IHD_to_DD_p = ihd2dd, DD_to_IHD_p = dd2ihd, lag = p_sel)
  }, error = function(e) tibble(IHD_to_DD_p = NA, DD_to_IHD_p = NA, lag = p_sel))
  return(res)
}

# 5. 分组分析
results <- df_all %>%
  group_by(location_name) %>%
  group_modify(~ granger_var_by_country(.x, max_p = 2)) %>%
  ungroup()

# 6. 多重校正 & 方向性
results <- results %>%
  mutate(
    IHD_to_DD_padj = p.adjust(IHD_to_DD_p, method = "BH"),
    DD_to_IHD_padj = p.adjust(DD_to_IHD_p, method = "BH"),
    direction = case_when(
      IHD_to_DD_padj < 0.05 & DD_to_IHD_padj < 0.05 ~ "Bidirectional",
      IHD_to_DD_padj < 0.05 ~ "IHD→DD",
      DD_to_IHD_padj < 0.05 ~ "DD→IHD",
      TRUE ~ NA_character_
    )
  )

# 7. 保存
write.csv(results, file.path(output_dir, "IHD_DD_SDI_VAR_Granger_Results_NoSex.csv"), row.names = FALSE)
print(head(results, 10))


#-------------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(vars)
library(vroom)

# 1. 读入数据
ihd <- vroom::vroom(file.path(input_dir, "IHD_1992_2021_matrix.csv"))
dd  <- vroom::vroom(file.path(input_dir, "DD_1992_2021_matrix.csv"))

# 2. 转成长表
ihd_long <- ihd %>%
  pivot_longer(
    cols = starts_with("val_"),
    names_to = "year",
    names_prefix = "val_",
    values_to = "IHD_val"
  ) %>%
  mutate(year = as.integer(year))

dd_long <- dd %>%
  pivot_longer(
    cols = starts_with("val_"),
    names_to = "year",
    names_prefix = "val_",
    values_to = "DD_val"
  ) %>%
  mutate(year = as.integer(year))

# 3. 合并
df_all <- ihd_long %>%
  left_join(dd_long,  by = c("location_name", "year"))

# 4. 批量VAR+Granger（不含SDI）
granger_var_by_country_nosdi <- function(df, max_p = 2){
  df <- df %>% arrange(year)
  # 要求无NA且年份数量足够
  if(any(is.na(df$IHD_val)) | any(is.na(df$DD_val)) | nrow(df) < (max_p+1)) {
    return(tibble(IHD_to_DD_p = NA, DD_to_IHD_p = NA, lag = NA))
  }
  # 自动选阶数
  p_sel <- min(VARselect(df[,c("IHD_val", "DD_val")], lag.max = max_p)$selection["AIC(n)"], max_p)
  # 建模+因果检验
  res <- tryCatch({
    model <- VAR(df[,c("IHD_val", "DD_val")], p = p_sel, type = "const")
    ihd2dd <- causality(model, cause = "IHD_val")$Granger$p.value
    dd2ihd <- causality(model, cause = "DD_val")$Granger$p.value
    tibble(IHD_to_DD_p = ihd2dd, DD_to_IHD_p = dd2ihd, lag = p_sel)
  }, error = function(e) tibble(IHD_to_DD_p = NA, DD_to_IHD_p = NA, lag = p_sel))
  return(res)
}

# 5. 分组分析
results_nosdi <- df_all %>%
  group_by(location_name) %>%
  group_modify(~ granger_var_by_country_nosdi(.x, max_p = 2)) %>%
  ungroup()

# 6. 多重校正 & 方向性
results_nosdi <- results_nosdi %>%
  mutate(
    IHD_to_DD_padj = p.adjust(IHD_to_DD_p, method = "BH"),
    DD_to_IHD_padj = p.adjust(DD_to_IHD_p, method = "BH"),
    direction = case_when(
      IHD_to_DD_padj < 0.05 & DD_to_IHD_padj < 0.05 ~ "Bidirectional",
      IHD_to_DD_padj < 0.05 ~ "IHD→DD",
      DD_to_IHD_padj < 0.05 ~ "DD→IHD",
      TRUE ~ NA_character_
    )
  )

# 7. 保存
write.csv(results_nosdi, file.path(output_dir, "IHD_DD_VAR_Granger_Results_NoSDI.csv"), row.names = FALSE)
print(head(results_nosdi, 10))




if (render_map) {
#============================================================
# 可视化分析 - Granger因果关系 (带SDI调整)
#============================================================
library(dplyr)
library(ggplot2)
library(maps)
library(readr)

#---------------------------------------------
# 1. 读取Granger结果（带SDI）
#---------------------------------------------
results_sdi <- read_csv(file.path(output_dir, "IHD_DD_SDI_VAR_Granger_Results_NoSex.csv"))

#---------------------------------------------
# 2. 国家名称标准化（完整映射）
#---------------------------------------------
manual_map <- c(
  "Republic of the Union of Myanmar" = "Myanmar",
  "Taiwan (Province of China)" = "Taiwan",
  "Republic of the Marshall Islands" = "Marshall Islands",
  "Turkmenistan" = "Turkmenistan",
  "Kingdom of Cambodia" = "Cambodia",
  "Democratic Socialist Republic of Sri Lanka" = "Sri Lanka",
  "Republic of Armenia" = "Armenia",
  "Independent State of Papua New Guinea" = "Papua New Guinea",
  "Democratic Republic of Timor-Leste" = "Timor-Leste",
  "Georgia" = "Georgia",
  "Lao People's Democratic Republic" = "Laos",
  "Solomon Islands" = "Solomon Islands",
  "Bosnia and Herzegovina" = "Bosnia and Herzegovina",
  "Republic of Maldives" = "Maldives",
  "Republic of the Philippines" = "Philippines",
  "Kyrgyz Republic" = "Kyrgyzstan",
  "Republic of Kiribati" = "Kiribati",
  "Democratic People's Republic of Korea" = "North Korea",
  "Republic of Croatia" = "Croatia",
  "Republic of Vanuatu" = "Vanuatu",
  "Republic of Tajikistan" = "Tajikistan",
  "Republic of Uzbekistan" = "Uzbekistan",
  "Republic of Indonesia" = "Indonesia",
  "Federated States of Micronesia" = "Micronesia",
  "Independent State of Samoa" = "Samoa",
  "Kingdom of Thailand" = "Thailand",
  "Republic of Azerbaijan" = "Azerbaijan",
  "Republic of Kazakhstan" = "Kazakhstan",
  "Socialist Republic of Viet Nam" = "Vietnam",
  "Kingdom of Tonga" = "Tonga",
  "Republic of Albania" = "Albania",
  "Malaysia" = "Malaysia",
  "Principality of Andorra" = "Andorra",
  "Federal Republic of Germany" = "Germany",
  "Kingdom of Belgium" = "Belgium",
  "New Zealand" = "New Zealand",
  "Republic of Iceland" = "Iceland",
  "State of Israel" = "Israel",
  "Republic of Austria" = "Austria",
  "Republic of Cyprus" = "Cyprus",
  "Hellenic Republic" = "Greece",
  "Commonwealth of the Bahamas" = "Bahamas",
  "Dominican Republic" = "Dominican Republic",
  "Republic of El Salvador" = "El Salvador",
  "Grenada" = "Grenada",
  "Republic of Cuba" = "Cuba",
  "Republic of Ecuador" = "Ecuador",
  "Republic of Italy" = "Italy",
  "Republic of Chile" = "Chile",
  "Republic of Costa Rica" = "Costa Rica",
  "Ireland" = "Ireland",
  "Republic of Guatemala" = "Guatemala",
  "Republic of Panama" = "Panama",
  "Bolivarian Republic of Venezuela" = "Venezuela",
  "Saint Lucia" = "Saint Lucia",
  "Commonwealth of Dominica" = "Dominica",
  "United Mexican States" = "Mexico",
  "People's Republic of China" = "China",
  "Republic of Fiji" = "Fiji",
  "Republic of Iraq" = "Iraq",
  "Kingdom of Saudi Arabia" = "Saudi Arabia",
  "Republic of Finland" = "Finland",
  "Ukraine" = "Ukraine",
  "United Kingdom of Great Britain and Northern Ireland" = "UK",
  "Republic of Malta" = "Malta",
  "Republic of Singapore" = "Singapore",
  "Mongolia" = "Mongolia",
  "Republic of Slovenia" = "Slovenia",
  "Palestine" = "Palestine",
  "Republic of Poland" = "Poland",
  "Republic of Yemen" = "Yemen",
  "Republic of Lithuania" = "Lithuania",
  "Kingdom of Bahrain" = "Bahrain",
  "Hashemite Kingdom of Jordan" = "Jordan",
  "Republic of Paraguay" = "Paraguay",
  "Kingdom of Denmark" = "Denmark",
  "Syrian Arab Republic" = "Syria",
  "Australia" = "Australia",
  "Republic of Turkey" = "Turkey",
  "Republic of Bulgaria" = "Bulgaria",
  "Republic of Tunisia" = "Tunisia",
  "People's Republic of Bangladesh" = "Bangladesh",
  "State of Qatar" = "Qatar",
  "Islamic Republic of Afghanistan" = "Afghanistan",
  "North Macedonia" = "North Macedonia",
  "Hungary" = "Hungary",
  "Federal Democratic Republic of Nepal" = "Nepal",
  "Republic of Estonia" = "Estonia",
  "Russian Federation" = "Russia",
  "Japan" = "Japan",
  "Republic of Peru" = "Peru",
  "Republic of Serbia" = "Serbia",
  "Republic of Angola" = "Angola",
  "Republic of Belarus" = "Belarus",
  "Republic of Korea" = "South Korea",
  "Kingdom of Norway" = "Norway",
  "Slovak Republic" = "Slovakia",
  "Eastern Republic of Uruguay" = "Uruguay",
  "Montenegro" = "Montenegro",
  "Romania" = "Romania",
  "Brunei Darussalam" = "Brunei",
  "Republic of Latvia" = "Latvia",
  "Republic of Moldova" = "Moldova",
  "Argentine Republic" = "Argentina",
  "Central African Republic" = "Central African Republic",
  "Sultanate of Oman" = "Oman",
  "Saint Vincent and the Grenadines" = "Saint Vincent",
  "Belize" = "Belize",
  "Portuguese Republic" = "Portugal",
  "Kingdom of Sweden" = "Sweden",
  "United States of America" = "USA",
  "Barbados" = "Barbados",
  "Plurinational State of Bolivia" = "Bolivia",
  "Kingdom of Spain" = "Spain",
  "Swiss Confederation" = "Switzerland",
  "Canada" = "Canada",
  "Jamaica" = "Jamaica",
  "Republic of Guyana" = "Guyana",
  "Grand Duchy of Luxembourg" = "Luxembourg",
  "Kingdom of the Netherlands" = "Netherlands",
  "United Republic of Tanzania" = "Tanzania",
  "Republic of Guinea-Bissau" = "Guinea-Bissau",
  "Togolese Republic" = "Togo",
  "Republic of Sierra Leone" = "Sierra Leone",
  "Republic of San Marino" = "San Marino",
  "Republic of Guinea" = "Guinea",
  "Federal Republic of Nigeria" = "Nigeria",
  "Cook Islands" = "Cook Islands",
  "Islamic Republic of Mauritania" = "Mauritania",
  "Republic of Burundi" = "Burundi",
  "Republic of Palau" = "Palau",
  "Republic of Djibouti" = "Djibouti",
  "Republic of Chad" = "Chad",
  "Republic of Niue" = "Niue",
  "Puerto Rico" = "Puerto Rico",
  "Republic of Madagascar" = "Madagascar",
  "Union of the Comoros" = "Comoros",
  "Republic of Malawi" = "Malawi",
  "Republic of Mali" = "Mali",
  "Republic of Sudan" = "Sudan",
  "Republic of Zimbabwe" = "Zimbabwe",
  "Republic of Kenya" = "Kenya",
  "Northern Mariana Islands" = "Northern Mariana Islands",
  "Republic of Senegal" = "Senegal",
  "Greenland" = "Greenland",
  "Republic of Haiti" = "Haiti",
  "Republic of Honduras" = "Honduras",
  "Republic of Nicaragua" = "Nicaragua",
  "Republic of Suriname" = "Suriname",
  "Federative Republic of Brazil" = "Brazil",
  "Republic of Colombia" = "Colombia",
  "Bermuda" = "Bermuda",
  "Republic of Equatorial Guinea" = "Equatorial Guinea",
  "Burkina Faso" = "Burkina Faso",
  "Tokelau" = "New Zealand",
  "Republic of Botswana" = "Botswana",
  "Saint Kitts and Nevis" = "Saint Kitts and Nevis",
  "Republic of Nauru" = "Nauru",
  "Republic of Mozambique" = "Mozambique",
  "Republic of Rwanda" = "Rwanda",
  "Republic of Côte d'Ivoire" = "Ivory Coast",
  "Republic of the Gambia" = "Gambia",
  "State of Kuwait" = "Kuwait",
  "Lebanese Republic" = "Lebanon",
  "State of Libya" = "Libya",
  "Kingdom of Morocco" = "Morocco",
  "Republic of the Niger" = "Niger",
  "State of Eritrea" = "Eritrea",
  "Democratic Republic of Sao Tome and Principe" = "Sao Tome and Principe",
  "Republic of Benin" = "Benin",
  "Republic of India" = "India",
  "People's Democratic Republic of Algeria" = "Algeria",
  "Arab Republic of Egypt" = "Egypt",
  "Islamic Republic of Iran" = "Iran",
  "Republic of the Congo" = "Republic of Congo",
  "Kingdom of Bhutan" = "Bhutan",
  "Islamic Republic of Pakistan" = "Pakistan",
  "Republic of Seychelles" = "Seychelles",
  "Republic of Cabo Verde" = "Cape Verde",
  "Republic of Cameroon" = "Cameroon",
  "American Samoa" = "American Samoa",
  "United States Virgin Islands" = "Virgin Islands",
  "Principality of Monaco" = "Monaco",
  "Republic of Ghana" = "Ghana",
  "Federal Republic of Somalia" = "Somalia",
  "Republic of Uganda" = "Uganda",
  "Republic of South Sudan" = "South Sudan",
  "Guam" = "Guam",
  "Republic of Liberia" = "Liberia",
  "Republic of South Africa" = "South Africa",
  "Kingdom of Lesotho" = "Lesotho",
  "Tuvalu" = "Tuvalu",
  "Republic of Namibia" = "Namibia",
  "Republic of Zambia" = "Zambia",
  "Gabonese Republic" = "Gabon",
  "Republic of Mauritius" = "Mauritius",
  "Federal Democratic Republic of Ethiopia" = "Ethiopia",
  "Kingdom of Eswatini" = "Swaziland"
)


results_sdi <- results_sdi %>%
  mutate(location_name = recode(location_name, !!!manual_map))

results_sdi <- results_sdi %>%
  mutate(location_name = case_when(
    location_name == "Antigua and Barbuda" ~ "Antigua",
    location_name == "French Republic" ~ "France",
    location_name == "Republic of Trinidad and Tobago" ~ "Trinidad",
    location_name == "Saint Kitts and Nevis" ~ "Saint Kitts",
    TRUE ~ location_name
  ))

#---------------------------------------------
# 3. 处理NA为 "No Significant"
#---------------------------------------------
results_sdi <- results_sdi %>%
  mutate(direction = ifelse(is.na(direction), "No Significant", direction)) %>%
  mutate(direction = factor(direction,
                            levels = c("Bidirectional", "DD→IHD", "IHD→DD", "No Significant")))

#---------------------------------------------
# 4. 获取世界地图数据
#---------------------------------------------
world_map <- map_data("world")
map_df <- left_join(world_map, results_sdi, by = c("region" = "location_name"))

# 检查是否还有NA
unmatched <- setdiff(results_sdi$location_name, unique(world_map$region))
cat("仍未匹配国家数量：", length(unmatched), "\n")
print(unmatched)

#---------------------------------------------
# 5. 绘图
#---------------------------------------------
map_df <- map_df %>% filter(!is.na(direction))
sci_colors <- c(
  "Bidirectional" = "#e85e62",  # 浅蓝色
  "DD→IHD" = "#a2c986",         # 绿色
  "IHD→DD" = "#f59c7c",         # 橙色
  "No Significant" = "#49c2d9"  # 粉红色
)

ggplot(map_df, aes(x = long, y = lat, group = group, fill = direction)) +
  geom_polygon(color = "black", size = 0.05) +
  scale_fill_manual(values = sci_colors, name = "Granger Causality Direction") +
  theme_void() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16)
  ) +
  labs(
    title = "Global Granger Causality Directions between IHD and DD (with SDI adjustment)"
  )

ggsave(file.path(output_dir, "Figure5_archived_layout_candidate.pdf"),
       plot = last_plot(), width = 12, height = 6)
}

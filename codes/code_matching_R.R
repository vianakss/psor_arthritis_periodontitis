install.packages("haven")
install.packages("MatchIt")
install.packages("writexl")
install.packages("readxl")

library(haven)
library(MatchIt)
library(writexl)
library(readxl)

setwd("c:your/path")
dados <- read_excel("dataset.xlsx")

dados$sex <- factor(dados$sex, levels = c(0, 1), labels = c("Female", "Male"))
dados$age <- factor(dados$age)

str(dados)

set.seed(12345)
m <- matchit(
  case_status ~ sex + age,
  data = dados,
  method = "nearest",
  distance = "mahalanobis",
  ratio = 1,
  exact = ~ sex + age
)

matched_data <- match.data(m)
table(matched_data$case_status)
write_xlsx(matched_data, "matched_dataset_1-1.xlsx")

#' @Nombre: heterogeneity_rpci.R
#' 
#' @Author: Marco Medina
#' 
#' @Descripción: Create graphs about heterogeneity in the RPCI effect.
#' 
#' @In: b_dcdh_heterogeneity.csv (exported from A_04_dcdh_heterogeneity_rpci.do)
#'      se_dcdh_heterogeneity.csv (exported from A_04_dcdh_heterogeneity_rpci.do)
#' 
#' @Out: 
#' 

# Libraries
pacman::p_load(readr, dplyr, ggplot2, ggthemes, scales, tidyr, stringr)

# Load data
b <- read_delim("01_Data/04_Temp/b_dcdh_heterogeneity.csv", delim = "|") %>%
  select(-cambio_cierre, -sal_diff) %>%
  pivot_longer(cols = c(alta, sal_formal, sal_cierre, log_sal_cierre),
               names_to = "var", 
               values_to = "b")

se <- read_delim("01_Data/04_Temp/se_dcdh_heterogeneity.csv", delim = "|") %>%
  select(-cambio_cierre, -sal_diff) %>%
  pivot_longer(cols = c(alta, sal_formal, sal_cierre, log_sal_cierre),
               names_to = "var", 
               values_to = "se")

# Create database with confidence intervals and significance
data <- b %>% 
  left_join(se) %>%
  mutate(p_value = 2*(1-pnorm(abs(b/se)))) %>%
  mutate(signif = ifelse(p_value <= 0.01,
                         "***",
                         ifelse(p_value <= 0.05,
                                "**",
                                ifelse(p_value <= 0.1,
                                       "*",
                                       "")))) %>%
  mutate(upper_ci = b + 1.96*se,
         lower_ci = b - 1.96*se) %>%
  mutate(type = ifelse(str_detect(hetero_var, pattern = "^size"),
                       7,
                       ifelse(str_detect(hetero_var, pattern = "^ind"),
                              6,
                              ifelse(str_detect(hetero_var, pattern = "^reg"),
                                     5,
                                     ifelse(str_detect(hetero_var, pattern = "frontera"),
                                            4,
                                            ifelse(str_detect(hetero_var, pattern = "^sal_min"),
                                                   3,
                                                   ifelse(str_detect(hetero_var, pattern = "^age"),
                                                          2,
                                                          1)))))))

# Factor variables
data$hetero_var <- factor(data$hetero_var,
                          levels = c("size_1001",
                                     "size_501",
                                     "size_251",
                                     "size_51",
                                     "size_6",
                                     "size_2",
                                     "size_1",
                                     "ind_services",
                                     "ind_transport",
                                     "ind_commerce",
                                     "ind_constr",
                                     "ind_transf",
                                     "ind_agricul",
                                     "reg_sur",
                                     "reg_norte",
                                     "reg_centro_occ",
                                     "reg_centro",
                                     "no_frontera",
                                     "frontera",
                                     "sal_min_5",
                                     "sal_min_3_5",
                                     "sal_min_2_3",
                                     "sal_min_1_2",
                                     "age_65",
                                     "age_55_65",
                                     "age_45_55",
                                     "age_35_45",
                                     "age_25_35",
                                     "age_15_25",
                                     "base_te",
                                     "base_outsourcing",
                                     "mujer",
                                     "hombre"),
                          labels = c("1000+ workers",
                                     "501-1000 workers",
                                     "251-500 workers",
                                     "51-250 workers",
                                     "6-50 workers",
                                     "2-5 workers",
                                     "1 workers",
                                     "Services",
                                     "Transportation & Comunication",
                                     "Commerce",
                                     "Construction",
                                     "Transformation",
                                     "Agriculture",
                                     "South-East",
                                     "North",
                                     "Central-West",
                                     "Central",
                                     "Away from MX-USA Border",
                                     "MX-USA Border",
                                     "More than 5 minimum wages",
                                     "3 to 5 minumum wages",
                                     "2 to 3 minumum wages",
                                     "1 to 2 minumum wages",
                                     "65+ years old",
                                     "55 to 65 years old",
                                     "45 to 55 years old",
                                     "35 to 45 years old",
                                     "25 to 35 years old",
                                     "15 to 25 years old",
                                     "Eventual",
                                     "Outsourcing",
                                     "Woman",
                                     "Man"))

data$var <- factor(data$var,
                   levels = c("alta",
                              "sal_formal",
                              "sal_cierre",
                              "log_sal_cierre"),
                   labels = c("Enrolled",
                              "Formal Wage",
                              "Wage",
                              "Log Wage"))

data$type <- factor(data$type,
                    levels = c(1:7),
                    labels = c("Worker characteristics",
                               "Worker age",
                               "Worker wage in min. wages",
                               "Job Location: MX-US Border",
                               "Job Location: Regions",
                               "Firm Industry",
                               "Firm Size"))

  

## Graphs ----------------------------------------------------------------------

# Worker Characteristics
ggplot(data %>% filter(hetero_var != "65+ years old", type %in% c("Worker characteristics",
                                                                  "Worker age",
                                                                  "Worker wage in min. wages")),
       aes(x = hetero_var, y = b, color = type, alpha = signif)) +
  facet_wrap(~var,
             ncol = 4,
             scales = "free_x") + 
  geom_point(aes(shape = type), size = 2) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci, size = signif), width = 0.3) +
  geom_hline(yintercept = 0, color = "black", alpha = 0.75, lty = 2) +
  scale_color_manual(name = "Heterogeneity type",
                     values = c("#004586", "#ff420e", "#579d1c")) +
  scale_shape_manual(name = "Heterogeneity type",
                     values = c(16, 15, 17)) +
  scale_size_discrete(name = "Coefficient significance",
                      range = c(0.6, 0.9)) +
  scale_alpha_discrete(name = "Coefficient significance",
                       range = c(0.5, 1)) +
  guides(color = guide_legend(order = 1),
         shape = guide_legend(order = 1),
         size = guide_legend(order = 2),
         alpha = guide_legend(order = 2)) +
  coord_flip() +
  labs(x = "Heterogeneity variable",
       y = "Average effect") +
  theme_calc() +
  theme(plot.background = element_blank())

ggsave("04_Figures/muestra_10porciento/dcdh_heterogeneity_worker_characteristics.pdf",
       width = 12,
       height = 5)


# Firm Characteristics
ggplot(data %>% filter(hetero_var != "65+ years old", !(type %in% c("Worker characteristics",
                                                                    "Worker age",
                                                                    "Worker wage in min. wages"))),
       aes(x = hetero_var, y = b, color = type, alpha = signif)) +
  facet_wrap(~var,
             ncol = 4,
             scales = "free_x") + 
  geom_point(aes(shape = type), size = 2) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci, size = signif), width = 0.3) +
  geom_hline(yintercept = 0, color = "black", alpha = 0.75, lty = 2) +
  scale_color_manual(name = "Heterogeneity type",
                     values = c("#004586", "#ff420e", "#579d1c", "#ff950e")) +
  scale_shape_manual(name = "Heterogeneity type",
                     values = c(16, 15, 17, 18)) +
  scale_size_discrete(name = "Coefficient significance",
                      range = c(0.6, 0.9)) +
  scale_alpha_discrete(name = "Coefficient significance",
                       range = c(0.5, 1)) +
  guides(color = guide_legend(order = 1),
         shape = guide_legend(order = 1),
         size = guide_legend(order = 2),
         alpha = guide_legend(order = 2)) +
  coord_flip() +
  labs(x = "Heterogeneity variable",
       y = "Average effect") +
  theme_calc() +
  theme(plot.background = element_blank())

ggsave("04_Figures/muestra_10porciento/dcdh_heterogeneity_firm_characteristics.pdf",
       width = 12,
       height = 7)

## Paper Graphs without log wage -----------------------------------------------

# Worker Characteristics
ggplot(data %>% filter(hetero_var != "65+ years old",
                       type %in% c("Worker characteristics",
                                   "Worker age",
                                   "Worker wage in min. wages"),
                       var != "Log Wage"),
       aes(x = hetero_var, y = b, color = type, alpha = signif)) +
  facet_wrap(~var,
             ncol = 4,
             scales = "free_x") + 
  geom_point(aes(shape = type), size = 2) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci, size = signif), width = 0.3) +
  geom_hline(yintercept = 0, color = "black", alpha = 0.75, lty = 2) +
  scale_color_manual(name = "Heterogeneity type",
                     values = c("#004586", "#ff420e", "#579d1c")) +
  scale_shape_manual(name = "Heterogeneity type",
                     values = c(16, 15, 17)) +
  scale_size_discrete(name = "Coefficient significance",
                      range = c(0.6, 0.9)) +
  scale_alpha_discrete(name = "Coefficient significance",
                       range = c(0.5, 1)) +
  guides(color = guide_legend(order = 1),
         shape = guide_legend(order = 1),
         size = guide_legend(order = 2),
         alpha = guide_legend(order = 2)) +
  coord_flip() +
  labs(x = "Heterogeneity variable",
       y = "Average effect") +
  theme_calc() +
  theme(plot.background = element_blank())

ggsave("04_Figures/muestra_10porciento/dcdh_heterogeneity_worker_characteristics_paper.pdf",
       width = 12,
       height = 5)


# Firm Characteristics
ggplot(data %>% filter(hetero_var != "65+ years old",
                       !(type %in% c("Worker characteristics",
                                     "Worker age",
                                     "Worker wage in min. wages")),
                       var != "Log Wage"),
       aes(x = hetero_var, y = b, color = type, alpha = signif)) +
  facet_wrap(~var,
             ncol = 4,
             scales = "free_x") + 
  geom_point(aes(shape = type), size = 2) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci, size = signif), width = 0.3) +
  geom_hline(yintercept = 0, color = "black", alpha = 0.75, lty = 2) +
  scale_color_manual(name = "Heterogeneity type",
                     values = c("#004586", "#ff420e", "#579d1c", "#ff950e")) +
  scale_shape_manual(name = "Heterogeneity type",
                     values = c(16, 15, 17, 18)) +
  scale_size_discrete(name = "Coefficient significance",
                      range = c(0.6, 0.9)) +
  scale_alpha_discrete(name = "Coefficient significance",
                       range = c(0.5, 1)) +
  guides(color = guide_legend(order = 1),
         shape = guide_legend(order = 1),
         size = guide_legend(order = 2),
         alpha = guide_legend(order = 2)) +
  coord_flip() +
  labs(x = "Heterogeneity variable",
       y = "Average effect") +
  theme_calc() +
  theme(plot.background = element_blank())

ggsave("04_Figures/muestra_10porciento/dcdh_heterogeneity_firm_characteristics_paper.pdf",
       width = 12,
       height = 7)




         
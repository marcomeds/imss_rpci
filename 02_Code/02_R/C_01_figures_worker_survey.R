#' @Nombre: figures_worker_survey.R
#' 
#' @Author: Marco Medina
#' 
#' @Descripción: Create graphs about the RPCI survey.
#' 
#' @In: worker_survey.csv (exported from features_worker_survey.do)
#' @Out: 

# Libraries
pacman::p_load(readr, dplyr, ggplot2, ggthemes, scales, tidyr, stringr)

# Load data
worker_survey <- read_delim("01_Data/03_Working/worker_survey.csv", delim = "|")

## Graphs ----------------------------------------------------------------------
# Knowledge and reported wage
data_knows_accident_insurance <- worker_survey %>%
  select(knows_accident_insurance) %>%
  filter(!is.na(knows_accident_insurance)) %>%
  mutate(count = n()) %>%
  group_by(knows_accident_insurance) %>%
  summarise(perc = n()/count) %>%
  mutate(var = "1_knows_accident_insurance") %>%
  distinct() %>%
  rename(answer = knows_accident_insurance)

data_knows_wage_impact_savings <- worker_survey %>%
  select(knows_wage_impact_savings) %>%
  filter(!is.na(knows_wage_impact_savings)) %>%
  mutate(count = n()) %>%
  group_by(knows_wage_impact_savings) %>%
  summarise(perc = n()/count) %>%
  mutate(var = "2_knows_wage_impact_savings") %>%
  distinct() %>%
  rename(answer = knows_wage_impact_savings)

data_talked_reported_wage <- worker_survey %>%
  select(talked_reported_wage) %>%
  filter(!is.na(talked_reported_wage)) %>%
  mutate(count = n()) %>%
  group_by(talked_reported_wage) %>%
  summarise(perc = n()/count) %>%
  mutate(var = "3_talked_reported_wage") %>%
  distinct() %>%
  rename(answer = talked_reported_wage)

data_reported_complete_wage <- worker_survey %>%
  select(reported_complete_wage) %>%
  filter(!is.na(reported_complete_wage)) %>%
  mutate(count = n()) %>%
  group_by(reported_complete_wage) %>%
  summarise(perc = n()/count) %>%
  mutate(var = "4_reported_complete_wage") %>%
  distinct() %>%
  rename(answer = reported_complete_wage)

data_registered_imss <- worker_survey %>%
  select(registered_imss) %>%
  filter(!is.na(registered_imss)) %>%
  mutate(count = n()) %>%
  group_by(registered_imss) %>%
  summarise(perc = n()/count) %>%
  mutate(var = "5_registered_imss") %>%
  distinct() %>%
  rename(answer = registered_imss)


data_knows_imss <- rbind(data_knows_accident_insurance, data_knows_wage_impact_savings, 
                         data_talked_reported_wage, data_reported_complete_wage,
                         data_registered_imss) %>%
  arrange(answer) %>%
  mutate(answer = factor(answer,
                         levels = c(-1, 0, 1),
                         labels = c("Don't know", "No", "Yes")))

labels_knows_imss <- c("Did your employer enroll you at IMSS?",
                       "Did your employer report your complete wage to IMSS?",
                       "Did you talk with your employer about which wage report to IMSS?",
                       "Did you know that part of your reported wage at IMSS goes to your retirment savings account?",
                       "Did you know that you have accident insurance, proportional to your reported wage at IMSS, if you're enrolled?")

ggplot(data_knows_imss) +
  geom_col(aes(x = var, 
               y = perc,
               fill = answer)) +
  scale_x_discrete(labels = rev(str_wrap(labels_knows_imss, width = 60))) +
  scale_y_continuous(labels = percent, breaks = 0.1*c(0:10)) +
  scale_fill_manual(values = c("#ffd320", "#ff420e","#004586"),
                    guide = guide_legend(reverse = TRUE)) +
  labs(title = "",
       x = "",
       y = "Percentage of answers") +
  coord_flip() +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.text = element_text(color = "black"),
        text = element_text(size = 20),
        legend.position = "bottom",
        legend.title = element_blank())

ggsave("04_Figures/worker_survey/hist_knowledge_register_survey.pdf",
       width = 12,
       height = 5)

# Library -----------------------------------------------------------------
library(rtweet)
library(dplyr)
library(stringr)
library(textclean)
library(tidytext)
library(ggplot2)

# About -------------------------------------------------------------------

# First "real" repo using Github Desktop.

# Collect & Subset Data ---------------------------------------------------

# Collect up to 20k tweets containing GME, up until 6:59PM on Friday.
rt <- search_tweets(q = "GME", 
                    n = 20000, 
                    max_id = 1370524864071696386,
                    lang = "en")

write_as_csv(rt, "data/GME_03132021.csv")

# Tokenization ------------------------------------------------------------

# Retain the timestamp and then tokenize the tweets.
# Remove URLs and convert the ’ special character to a standard single quote '
tokens <- rt %>% 
  select(created_at, text) %>%
  mutate(text = str_replace_all(text, "http(s?)://(.*)[.][a-z]+", "")) %>%
  mutate(text = str_replace_all(text, "’", "\'")) %>%
  mutate(text = replace_contraction(text)) %>%
  unnest_tokens("word", "text")

# Get Sentiment Values ----------------------------------------------------

# Convert timezone, round to minutes, and coerce to character.
# Date is coerce to character to allow group_by() functionality.
attr(tokens$created_at, "tzone") <- "US/Eastern"
tokens$created_at <- round(tokens$created_at, units = "mins")
tokens$created_at <- as.character(tokens$created_at)

# Using the afinn dictionary due to its positive/negative scoring method
# and its dictionary terms.
dict <- get_sentiments("afinn")


# Group sentiment by time of day.
afinn_sent <- tokens %>%
  inner_join(dict, by = "word") %>%
  group_by(created_at) %>%
  summarise(sentiment = mean(value)) %>%
  arrange(desc(created_at)) %>%
  mutate(created_at = as.POSIXct(created_at))


ggplot(afinn_sent, aes(x = created_at, y = sentiment)) + 
  geom_line(group = 1) + 
  labs(title = "Twitter GME Sentiment",
       x = "Time of Post") +
  theme_minimal() +
  scale_x_datetime(labels = scales::time_format("%H:%M"))
ggsave("output/TwitterGME.png")

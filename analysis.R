# Library -----------------------------------------------------------------

library(rtweet)      # Twitter API
library(dplyr)       # Data Cleaning
library(stringr)     # Data Cleaning
library(textclean)   # Data Cleaning
library(tidytext)    # Data Cleaning
library(syuzhet)     # Sentiment Analysis
library(ggplot2)     # Graphing
library(tidyquant)   # Stocks
library(scales)      # Scaling
# About -------------------------------------------------------------------

# First "real" repo using Github Desktop.
# Twitter GME Sentiment vs GME stock prices.

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
tokens$created_at <- as.POSIXct(tokens$created_at)
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
  arrange((created_at)) %>%
  mutate(created_at = as.POSIXct(created_at))

# Cut to 8AM - 7PM EST
afinn_sent <- afinn_sent[300:925, ]

ggplot(afinn_sent, aes(x = created_at, y = sentiment)) + 
  geom_line(group = 1) + 
  labs(title = "Twitter GME Sentiment",
       x = "Time of Post") +
  theme_minimal() 
ggsave("output/TwitterGME.png")


# Load Stock Prices -------------------------------------------------------

prices <- read.csv("data/prices.csv", fileEncoding = "UTF-8-BOM")
prices$time <- as.POSIXct(prices$time, tz = "US/Eastern")
str(prices)

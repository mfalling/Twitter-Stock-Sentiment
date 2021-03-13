# Library -----------------------------------------------------------------
library(rtweet)

# About -------------------------------------------------------------------

# First "real" repo using Github Desktop.

# Collect & Subset Data ---------------------------------------------------

# Collect up to 20k tweets containing GME, up until 6:59PM on Friday.
rt <- search_tweets(q = "GME", 
                    n = 20000, 
                    max_id = 1370524864071696386,
                    lang = "en")

write_as_csv(rt, "data/GME_03132021.csv")

# Clean Data --------------------------------------------------------------


